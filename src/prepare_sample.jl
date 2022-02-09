
using PyCall

py"""
import json
import os
import pickle
import math


def send_packet(packet: dict) -> bool:
    res = False
    if 'ip' in packet['_source']['layers'].keys():
        n = int(packet['_source']['layers']['ip']['ip.ttl'])
        if (n & (n - 1) == 0) and n != 0:
            res = True
    return res

def prepare_sample(filename='tmp.json'):
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


def create_samples(mal_path, clean_path, mal_sample_path, clean_sample_path):
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
                os.system('tshark -r {} -T json > tmp.json'.format(mal))
                with open(mal_sample_path+str(i), 'wb') as out_:
                    pickle.dump(prepare_sample(), out_)
            except:
                print('error')
            os.system('rm tmp.json')
    
    for i, clean in enumerate(clean_files):
        print(i, clean)
        try:
            os.system('tshark -r {} -T json > tmp.json'.format(clean))
            with open(clean_sample_path+str(i), 'wb') as out_:
                pickle.dump(prepare_sample(), out_)
        except:
            print('error')
        os.system('rm tmp.json')
"""

@doc """
    convert_jsons_2_pickle_samples(mal_path::String, clean_path::Stirng, 
        mal_sample_path::String, clean_sample_path::String)

Loads pcap samples stored on paths 'mal_path' and 'clean_path', extract features and 
stored them in pickle format on 'mal_sample_path' and 'clean_sample_path'.

From each packet are extract these features: packet direction, 
time difference to next recieved, time difference to next send, packet size.
""" ->
function convert_jsons_2_pickle_samples(mal_path::String, clean_path::Stirng, 
            mal_sample_path::String, clean_sample_path::String)
    py"create_samples"(mal_path, clean_path, mal_sample_path, clean_sample_path)
end
