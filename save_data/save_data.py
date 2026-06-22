#!/usr/bin/env python3
import rclpy
from rclpy.node import Node
from nav_msgs.msg import Odometry
from sensor_msgs.msg import LaserScan, NavSatFix
from std_msgs.msg import String
from geometry_msgs.msg import Vector3
import rosbag2_py
import time, threading
from rclpy.serialization import serialize_message

class BagRecorder(Node):
    def __init__(self):
        super().__init__('bag_recorder')

        # Subscribers
        self.scan_sub = self.create_subscription(LaserScan, "/scan", self.scan_callback, 10)
        self.gps_sub = self.create_subscription(NavSatFix, "/gps_raw", self.gps_callback, 10)
        self.gps_str_sub = self.create_subscription(String, "/gps_string", self.gps_string_callback, 10)
        self.heading_sub = self.create_subscription(Vector3, "/gps_heading", self.heading_callback, 10)

        # Writer and lock
        self.writer = None
        self.lock = threading.Lock()

        # Start background thread to rotate bags
        self.running = True
        self.bag_thread = threading.Thread(target=self.rotate_bags, daemon=True)
        self.bag_thread.start()

        self.get_logger().info("Custom rosbag recorder started (rotating every 30s).")

    def create_writer(self):
        bag_name = f"my_bag_{int(time.time())}"
        storage_options = rosbag2_py.StorageOptions(
            uri=bag_name,
            storage_id="sqlite3"
        )
        converter_options = rosbag2_py.ConverterOptions('', '')

        writer = rosbag2_py.SequentialWriter()
        writer.open(storage_options, converter_options)

        # Register topics
        writer.create_topic(rosbag2_py.TopicMetadata(
            name="/scan",
            type="sensor_msgs/msg/LaserScan",
            serialization_format="cdr"
        ))
        writer.create_topic(rosbag2_py.TopicMetadata(
            name="/gps_raw",
            type="sensor_msgs/msg/NavSatFix",
            serialization_format="cdr"
        ))
        writer.create_topic(rosbag2_py.TopicMetadata(
            name="/gps_string",
            type="std_msgs/msg/String",
            serialization_format="cdr"
        ))
        writer.create_topic(rosbag2_py.TopicMetadata(
            name="/gps_heading",
            type="geometry_msgs/msg/Vector3",
            serialization_format="cdr"
        ))

        return writer

    def rotate_bags(self):
        while self.running:
            with self.lock:
                self.writer = self.create_writer()
            self.get_logger().info("Opened new bag file.")
            time.sleep(30)  # keep bag open for 30s
            with self.lock:
                self.writer = None
            self.get_logger().info("Closed bag file (30s window finished).")

    # Callbacks
    def scan_callback(self, msg):
        self.write_msg("/scan", msg)

    def gps_callback(self, msg: NavSatFix):
        self.write_msg("/gps_raw", msg)

    def gps_string_callback(self, msg: String):
        self.write_msg("/gps_string", msg)

    def heading_callback(self, msg: Vector3):
        self.write_msg("/gps_heading", msg)

    def write_msg(self, topic, msg):
        with self.lock:
            if self.writer is None:
                return
            ser = serialize_message(msg)
            timestamp = self.get_clock().now().nanoseconds
            self.writer.write(topic, ser, timestamp)

def main(args=None):
    rclpy.init(args=args)
    node = BagRecorder()
    try:
        rclpy.spin(node)
    except KeyboardInterrupt:
        pass
    node.running = False
    node.destroy_node()
    rclpy.shutdown()

if __name__ == '__main__':
    main()

