#!/usr/bin/env python3
import rclpy
from rclpy.node import Node
from rclpy.callback_groups import ReentrantCallbackGroup
from std_msgs.msg import Int32
from pino_msgs.srv import Text   # custom srv
from pino_msgs.msg import AudioMSG   # ✅ use your custom message
import json
# External libs and your utils
from utils.IntentRouter import IntentRouter
from utils.LLMStreamClient import LLMStreamClient
from utils.Retriever import Retriever

from sentence_transformers import SentenceTransformer
import time, random
from pathlib import Path
import concurrent.futures

home_dir = Path.home()
TIMEOUT_THRESHOLD = 12.0
class TourGuideAgent(Node):
    def __init__(self):
        super().__init__("tour_guide_agent")

        # Callback groups
        self.service_group = ReentrantCallbackGroup()
        # self.timer_group = ReentrantCallbackGroup()

        self.voice = 'zf_xiaoyi'

        # Service server with custom srv
        self.srv = self.create_service(
            Text,
            "llm_service",
            self.handle_llm_service,
            callback_group=self.service_group
        )

        # Helpers
        self.router = IntentRouter()
        self.llm = LLMStreamClient()

        # ✅ Use ROS2 publisher instead of direct UDP sender
        self.audio_pub = self.create_publisher(AudioMSG, "audio_cmd", 10)

        self.shared_model = SentenceTransformer(str(home_dir) + "/model_data/bge-m3", device="cpu")

        self.database_dir = "./database/"
        self.info = Retriever(
            self.database_dir + "info.index",
            self.database_dir + "info_metadata.json",
            self.shared_model
        )
        self.shows = Retriever(
            self.database_dir + "shows.index",
            self.database_dir + "shows_metadata.json",
            self.shared_model
        )
        self.vendors = Retriever(
            self.database_dir + "vendors.index",
            self.database_dir + "vendors_metadata.json",
            self.shared_model
        )
        self.intro = Retriever(
            self.database_dir + "intro.index",
            self.database_dir + "intro_metadata.json",
            self.shared_model
        )
        self.poem = Retriever(
            self.database_dir + "poem.index",
            self.database_dir + "poem_metadata.json",
            self.shared_model
        )
        self.generated_poem = Retriever(
            self.database_dir + "generated_poem.index",
            self.database_dir + "generated_poem_metadata.json",
            self.shared_model
        )
        self.joke = None         
        with open(self.database_dir + "joke.json", "r", encoding="utf-8") as f:
            self.joke = json.load(f)
        self.finish_symbol = ["。", "！", "？","～", "：", "!", "?","~", ":" ] 
        self.online_warmup = ["好的，客官的这个问题问得我的大脑一阵空白，让我稍微冷静一下再回答你。",
            "卖锅的，这个问题问得真是刁钻，我得用我这聪明的脑子好好想一想。",
            "这个问题问得我快死机了，让我的cpu再加速运转一下，给您一个合理的答案！",
            "哎呀，额的神啊，真没想到你会问这个问题，这个我得查一下我的小本本！",
            "这个问题有点意思，看来您不是一般人啊，您得是二班的吧。哈哈哈",
            "听了您这个问题，我脑瓜子嗡嗡的，再多给我一点时间琢磨一下",
            "您这个问题问得太好了，您是第一个提出这个问题的游客，待我给您细细道来",
            "这位客官，请让我想想，好像唐明皇当年也提过同样的问题。",
            "恭喜您成为第八百八十八个提出这个问题的人，请稍等片刻，我得给你一个与众不同的答案。",
            "哎呀，这个问题可巧是问对人了，我敢说整个大唐芙蓉园也只有我能够给出最完美的答案了。"]
        self.last_cmd = time.time()
        self.last_busy_time = time.time()
        self.max_chunk_size = 60  # safeguard for long segments
        self.is_busy = False

        self.motion_cmd_pub = self.create_publisher(Int32, "motion_cmd", 10)
        # self.timer = self.create_timer(1.0, self.publish_status, callback_group=self.timer_group)

        self.get_logger().info("✅ Tour Guide Agent service ready at 'llm_service'")

    # ✅ helper to publish AudioMSG
    def publish_audio(self, text: str, cmd: str = 'speak', voice: str = 'zf_xiaoyi', volume: float = 3.0, speed: float = 0.9):
        msg = AudioMSG()
        msg.cmd = cmd
        msg.text = text
        msg.voice = voice
        msg.volume = volume
        msg.speed = speed
        self.audio_pub.publish(msg)
        self.get_logger().info(f"🎙️ Published AudioMSG: {msg}")

    # ------------------- Service handler -------------------
    def handle_llm_service(self, request, response):
        if self.is_busy:
            self.get_logger().warn("⏳ Service busy, ignoring new query.")
            response.success = True
            response.response = "系统正在处理上一个请求，请稍后再试。"
            return response
        
        self.is_busy = True
        try:
            user_text = request.text            
            self.get_logger().info(f"📥 Received: {user_text}")

            final_response = self.on_user_input(user_text)

            response.success = True
            response.response = final_response
        except Exception as e:
            self.get_logger().error(f"❌ Error: {e}")
            response.success = False
            response.response = "服务发生错误"
        finally:
            self.is_busy = False
        return response

    def voice_select(self, text):
        voice = 'zf_xiaoyi'
        t = text.strip()
        if any(k in t for k in ['陕西', '闪西','山西']):
            if any(k in t for k in ['话', '画', '化']):
                return 'zf_xiaoni'
        
        if any(k in t for k in ['东北']):
            if any(k in t for k in ['话', '画', '化']):
                return 'zf_xiaobei'
        return voice 

    # ------------------- Main Agent Logic -------------------
    def on_user_input(self, text: str) -> str:
        self.voice = self.voice_select(text)

        intent = self.router.classify(text)
        self.get_logger().info(f"🧭 Intent classified: {intent}")

        if intent == "POEM":
            return self.handle_poem_chat(text)
        elif intent == "GEN_POEM":
            return self.handle_gen_poem_chat(text)
        
        if intent == "INTRO":
            return self.handle_intro(text)
        elif intent == "SHOW":
            return self.handle_show(text)
        elif intent == "VENDOR":
            return self.handle_vendor(text)
        elif intent == "PLAY_MUSIC":
            return self.handle_music(text)
        elif intent == "PLAY_SONG":
            return self.handle_song(text)
        elif intent == "JOKE":
            return self.handle_joke(text)
        elif intent == "RANDOM_TALK":
            return self.handle_random_talk(text)
        results = self.info.retrieve(text, threshold=0.7, k=1)
        print(" DATABASE result: ", results)
        if not results:
            self.get_logger().info(f"NOT in the database")
        else:
            self.get_logger().info(f"FOUND in the database")
            context = results[0]['answer']
            self.publish_audio(context)
            return "DONE"

        return self.handle_chat(text)

    # ------------------- Handlers -------------------
    def handle_music(self, text: str) -> str:
        self.publish_audio(text = 'random', cmd = 'play')
        return "DONE"
    def handle_song(self, text: str) -> str:
        self.publish_audio(text = 'xian', cmd = 'play')
        return "DONE"

    def handle_random_talk(self, text: str) -> str:
        idx = random.randint(0, len(self.joke))
        if(self.joke[idx]['type'] == 'joke'):
            self.publish_audio( "让我来讲个笑话吧，" + self.joke[idx]['text'] )
        else:
            self.publish_audio( "下面是唐代科普时间，" + self.joke[idx]['text'] )
        return "DONE"

    def handle_joke(self, text: str) -> str:
        idx = random.randint(0, len(self.joke))
        while(self.joke[idx]['type'] != 'joke'):
            idx = random.randint(0, len(self.joke))

        self.publish_audio( "我想到一个笑话，" + self.joke[idx]['text'] )
        
        return "DONE"

    def handle_intro(self, text: str) -> str:
        results = self.intro.retrieve(text, threshold=0.3, k=1)
        if not results:
            self.publish_audio("抱歉，我没有找到相关信息。")
            return "抱歉，我没有找到相关信息。"

        context = '下面让我为主人介绍一下'
        for r in results:
            context += f"{r['name']}。"
            context += f"{r['description']}。"
        messages = [{"role": "assistant", "content": context, "llm": False}]
        return self.stream_and_send(messages, speed=1.0)

    def handle_chat(self, text: str) -> str:
        self.publish_audio( random.choice(self.online_warmup) )
        messages = [
            {"role": "system", "content": "你是旅游景区[大唐芙蓉园]导游机器人[小白],请用开朗,幽默的语言回答下列对话,不要推荐东西。"},
            {"role": "user", "content": text, "llm": True}
        ]
        return self.stream_and_send(messages)

    def handle_poem_chat(self, text: str) -> str:
        results = self.poem.retrieve(text, threshold=0.1, k=1)
        if not results:
            self.publish_audio("抱歉，我没有找到相关内容。")
            return "抱歉，我没有找到相关内容。"
        peom_output = '以下是我为主人找到的诗词,' + results[0]['author']+'的' + results[0]['title'] + '.'
        self.publish_audio(peom_output)
        context = results[0]['content'] + '.'
        messages = [{"role": "assistant", "content": context, "llm": False}]
        return self.stream_and_send(messages, speed=0.7)

    def handle_gen_poem_chat(self, text: str) -> str:
        results = self.generated_poem.retrieve(text, threshold=0.0, k=1)
        if not results:
            self.publish_audio("抱歉，我没有找到相关内容。")
            return "抱歉，我没有找到相关内容。"

        peom_output = '以下是我为主人创作的诗词,' + results[0]['title'] + '.'
        self.publish_audio(peom_output)
        context = results[0]['content'] + '.'
        messages = [{"role": "assistant", "content": context, "llm": False}]
        return self.stream_and_send(messages, speed=0.7)

    def handle_show(self, text: str) -> str:
        results = self.shows.retrieve(text, threshold=0.0, k=5)
        if not results:
            self.publish_audio("我没有找到相关的演出推荐。")
            return "我没有找到相关的演出推荐。"

        context = '我为你找到以下表演活动。'
        for r in results:
            context += f"{r['name']}-{r['time'].replace(':', '点')}-{r['location']}-{r['description']}。"
        messages = [{"role": "assistant", "content": context, "llm": False}]
        return self.stream_and_send(messages)

    def handle_vendor(self, text: str) -> str:
        results = self.vendors.retrieve(text, threshold=0.2, k=1)
        if not results:
            self.publish_audio("我没有找到相关的商铺推荐。")
            return "我没有找到相关的商铺推荐。"

        context = '我为你找到如下选项。'
        for r in results:
            context += f"商家名称，{r['name']}。 商家特点，{r['feature']}{r['description']}。"
        messages = [{"role": "assistant", "content": context, "llm": False}]
        return self.stream_and_send(messages)

    # ------------------- Streaming + Timeout + AudioMSG -------------------
    def stream_and_send(self, messages, temperature=1.3, speed=0.9) -> str:
        llm_required = messages[0].get("llm", True)
        buffer = ""

        # ---------- Non-LLM case ----------
        if not llm_required:
            text = messages[0]["content"]
            for token in text:
                buffer += token
                if token in self.finish_symbol:
                    segment = buffer.strip()
                    if len(segment) > 6:
                        self.publish_audio(segment, speed=speed)
                    buffer = ""
            if buffer.strip():
                self.publish_audio(buffer.strip(), speed=speed)
            return 'DONE'

        # ---------- LLM Streaming with Timeout ----------
        def generate_tokens():
            return list(self.llm.stream_generate(messages, temperature=temperature))

        try:
            with concurrent.futures.ThreadPoolExecutor(max_workers=1) as executor:
                future = executor.submit(generate_tokens)
                tokens = future.result(timeout=TIMEOUT_THRESHOLD)   # ⏳ wait max 2s
        except concurrent.futures.TimeoutError:
            self.get_logger().error(f"❌ LLM stream timeout after {TIMEOUT_THRESHOLD}s")
            self.publish_audio("抱歉，云端响应超时，请稍后再试。")
            return "FAILED"
        except Exception as e:
            self.get_logger().error(f"❌ LLM error: {e}")
            self.publish_audio("抱歉，云端响应失败。")
            return "FAILED"

        # ---------- Process tokens ----------
        for token in tokens:
            if token is None:
                continue
            buffer += token
            if token in self.finish_symbol:
                segment = buffer.strip()
                if len(segment) > 6:
                    self.publish_audio(segment, speed=speed)
                buffer = ""
        if buffer.strip():
            self.publish_audio(buffer.strip(), speed=speed)

        return 'DONE'


def main(args=None):
    rclpy.init(args=args)
    node = TourGuideAgent()

    from rclpy.executors import MultiThreadedExecutor
    executor = MultiThreadedExecutor()
    executor.add_node(node)

    try:
        executor.spin()
    except KeyboardInterrupt:
        pass
    finally:
        node.destroy_node()
        rclpy.shutdown()


if __name__ == "__main__":
    main()

