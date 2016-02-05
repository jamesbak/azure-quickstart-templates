from _io import open
from xml import dom
from xml import sax
from xml import *
from xml.etree.ElementTree import QName
import xml.etree.cElementTree as ET
import optparse
from optparse import OptionParser
import sys

filename = " "

if __name__ == "__main__":
    cluster_name=""
    cluster_password=""

    parser = OptionParser()
    parser.add_option("-n","--cn",dest="cluster_name") 
    parser.add_option("-p","--cp",dest="cluster_password")
    parser.add_option("-i","--ip",dest="ip_addresses")
    parser.add_option("-g","--pg",dest="partition_group")
    parser.add_option("-f","--fn",dest="filename")
    if len(sys.argv) > 0:
        opts,args = parser.parse_args(sys.argv)
        filename = opts.filename
        cluster_name = opts.cluster_name
        cluster_password = opts.cluster_password
        ## Opening the hazelcast.xml file
        try:
            f = open(filename)
            ## Registering default namespace
            ET.register_namespace('',"http://www.hazelcast.com/schema/config")
            ## Loading the root parser
            tree = ET.parse(f)    
            root = tree.getroot()
            hazelcast_ns= "http://www.hazelcast.com/schema/config"
        
            ## Updating group tags
            group = ET.Element("group")      
            name = ET.Element("name")
            name.text = cluster_name
            group.append(name)
            password = ET.Element("password")
            password.text = cluster_password    
            group.append(password)
        
            group_tag = str(QName(hazelcast_ns,"group"))
            ## Finding and replacing the old group tag with the new one

            for group_old in root.iter(group_tag):
            
                root.remove(group_old)
                root.insert(1,group)

            print("Updated cluster user name and password...")
            ## Updating IP address tags
            ip_addresses = ""
            addr_list = []
            ip_addresses = opts.ip_addresses
            addr_list = ip_addresses.split(',')
            tcp_node = ET.Element("tcp-ip")
            tcp_node.attrib = {"enabled":"true"}
            for addr in addr_list:
                ip_add = ET.Element("interface")
                ip_add.text = addr
                tcp_node.append(ip_add)
        
        
            network_tag = str(QName(hazelcast_ns,"network"))
            join_tag = str(QName(hazelcast_ns,"join"))
            tcp_ip_tag = str(QName(hazelcast_ns,"tcp-ip"))
            for n_tag in root.iter(network_tag):
                for j_tag in n_tag.iter(join_tag):
                    for tcp_tag in j_tag.iter(tcp_ip_tag):
                        j_tag.remove(tcp_tag)
                        j_tag.insert(1,tcp_node)

            print("Updated IP addresses of nodes...")
                             
            ## Updating the partition group tags
            partition_group_node = ET.Element("partition-group")
            partition_group_node.attrib = {"enabled":"true","group-type":"CUSTOM"}
            partition_group = ""
            partition_group = opts.partition_group
            group_list = []
            group_list = partition_group.split(';')
            for groups in group_list:
                group_node = None
                group_node = ET.Element("member-group")
                interface_list = []
                grp = str(groups)
                grp_index = grp.split(':')
                interface_list = grp_index[1].split(',')
                for interface in interface_list:
                    interface_node = None
                    interface_node = ET.Element("interface")
                    interface_node.text = interface
                    group_node.append(interface_node)
                partition_group_node.append(group_node)
        
            partition_group_tag = str(QName(hazelcast_ns,"partition-group"))
            for pg_tag in root.iter(partition_group_tag):
                root.remove(pg_tag)
                root.insert(4,partition_group_node)
            print("Updated partition groups...")
        
            tree.write(filename)
            print("Updating configuration file suceeded , file updated and saved at " + filename)
        except IOError as e:
            print("Unable to open configuration file, I/O error ({0}) : {1}".format(e.errno, e.strerror))
                   
    else:
        print("Script exited without executing, no input parameters found")
        

   
    

