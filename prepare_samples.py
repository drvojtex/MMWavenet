
import json
import os
import pickle
import math


def send_packet(packet: dict) -> bool:
    res = False
    if 'ip' in packet["_source"]["layers"].keys():
        n = int(packet["_source"]["layers"]["ip"]["ip.ttl"])
        if (n & (n - 1) == 0) and n != 0:
            res = True
    return res


def extract_packet_features(packet):
    packet = packet["_source"]["layers"]
    # tmp = [protocol, port, icmp_type, icmp_code, length, Flags, ack_val, urgpt_val, window_size, option_num]
    if "tcp" in packet:
        packet = packet["tcp"]
        if 'tcp.options_tree' in packet:
            options = len(packet["tcp.options_tree"]) / 40
        else:
            options = 0
        tmp = [
            1 / 3,
            int(packet["tcp.srcport"]) / 65535, int(packet["tcp.dstport"]) / 65535,
            0, 0,  # icmp_type, icmp_code
            int(packet["tcp.len"]) / 65535,  # length
            int(packet["tcp.flags"], base=16) / (2 ** 9 - 1),  # Flags
            int(packet["tcp.ack"]) / (2 ** 16 - 1),
            int(packet["tcp.urgent_pointer"]) / (2 ** 16 - 1),
            int(packet["tcp.window_size"]) / (2 ** 16 - 1),
            options
        ]
    elif "udp" in packet:
        packet = packet["udp"]
        tmp = [
            2 / 3,
            int(packet["udp.srcport"]) / 65535, int(packet["udp.dstport"]) / 65535,
            0, 0,  # icmp_type, icmp_code
            int(packet["udp.length"]) / 65535,  # length
            0,  # Flags
            0,  # Ack
            0,  # Urgent pointer
            0,  # window size
            0  # options tree
        ]
    elif "icmp" in packet:
        packet = packet["icmp"]
        tmp = [
            3 / 3,
            0, 0,  # ports
            int(packet["icmp.type"]) / 256,  # icmp type
            int(packet["icmp.code"]) / 256,  # icmp code
            int(packet["ip"]["ip.len"]) / 65535,  # length
            0, 0, 0, 0, 0
        ]
    else:
        tmp = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
    return tmp


def prepare_sample(filename="/largeandslow/kozel/dataset/tmp.json"):
    f = open(filename)
    pcap = json.load(f)
    f.close()
    packet_arr = []
    for i, packet in enumerate(pcap):
        # tmp = [direction, time diff to next recieved,
        #        time diff to next send, packet size]
        direction = int(send_packet(packet))
        time_diff_send = None
        time_diff_rcv = None
        time = float(packet['_source']['layers']['frame']['frame.time_relative'])
        for next_packet in pcap[i+1:]:
            tmp_direction = send_packet(next_packet)
            if not time_diff_rcv and not tmp_direction:
                time_diff_rcv = float(next_packet['_source']
                                       ['layers']['frame']
                                       ['frame.time_relative']) - time
            if not time_diff_send and tmp_direction:
                time_diff_send = float(next_packet['_source']
                                      ['layers']['frame']
                                      ['frame.time_relative']) - time

        packet_size = int(packet['_source']['layers']['frame']['frame.len'])
        tmp = [direction, math.log(1+time_diff_rcv),
               math.log(1+time_diff_send), float(packet_size)/2**16]
        tmp += extract_packet_features(packet)
        packet_arr.append(tmp)

        if i == 255:
            break
    return packet_arr


def create_samples(mal_path, clean_path):
    mal_files = [os.path.join(mal_path, f)
                 for f in os.listdir(mal_path)
                 if os.path.isfile(os.path.join(mal_path, f))]
    clean_files = [os.path.join(clean_path, f)
                   for f in os.listdir(clean_path)
                   if os.path.isfile(os.path.join(clean_path, f))]

    for i, mal in enumerate(mal_files):
        if i > 393:
            print(i, mal)
            try:
                os.system("tshark -r {} -T json > /largeandslow/kozel/dataset/tmp.json".format(mal))
                with open('/largeandslow/kozel/dataset/malware/mal'+str(i), 'wb') as out_:
                    pickle.dump(prepare_sample(), out_)
            except:
                print("error")
            os.system("rm /largeandslow/kozel/dataset/tmp.json")
    
    for i, clean in enumerate(clean_files):
        print(i, clean)
        try:
            os.system("tshark -r {} -T json > /largeandslow/kozel/dataset/tmp.json".format(clean))
            with open('/largeandslow/kozel/dataset/cleanware/clean'+str(i), 'wb') as out_:
                pickle.dump(prepare_sample(), out_)
        except:
            print("error")
        os.system("rm /largeandslow/kozel/dataset/tmp.json")


if __name__ == "__main__":
    create_samples("/largeandslow/kozel/pcaps/malwares",
                    "/largeandslow/kozel/pcaps/cleanware")

