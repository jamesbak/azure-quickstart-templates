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

    parser = OptionParser()
    parser.add_option("-n","--cn",dest="cluster_name") 
    parser.add_option("-p","--cp",dest="cluster_password")
    parser.add_option("-s","--si",dest="subscription_id")
    parser.add_option("-t","--ti",dest="tenant_id")
    parser.add_option("-a","--aci",dest="aad_client_id")
    parser.add_option("-c","--acs",dest="aad_client_secret")
    parser.add_option("-l","--ct",dest="cluster_tag")
    parser.add_option("-f","--fn",dest="filename")
    if len(sys.argv) > 0:
        opts,args = parser.parse_args(sys.argv)
        ## Opening the hazelcast.xml file
        try:
            ## f = open(opts.filename)
            ## Registering default namespace
            hazelcast_ns = "http://www.hazelcast.com/schema/config"
            ET.register_namespace('', hazelcast_ns)
            ns = {'hazelcast_ns': hazelcast_ns}
            ## Loading the root parser
            tree = ET.parse(opts.filename)    
            root = tree.getroot()
        
            ## Finding and replacing the old group tag with the new one
            for group in root.iter(str(QName(hazelcast_ns, "group"))):
                group.find("hazelcast_ns:name", ns).text = opts.cluster_name
                group.find("hazelcast_ns:password", ns).text = opts.cluster_password
            print("Updated cluster user name and password...")
            
            ## Updating discovery stategy
            print("Updating discovery strategy nodes...")
            for strategy in root.iter(str(QName(hazelcast_ns, "discovery-strategy"))):
                strategy_class = strategy.get("class")
                if strategy_class == "com.hazelcast.azure.AzureDiscoveryStrategy":
                    properties = strategy.find("hazelcast_ns:properties", ns);
                    properties.find("*/[@name='subscription-id']").text = opts.subscription_id
                    properties.find("*/[@name='tenant-id']").text = opts.tenant_id
                    properties.find("*/[@name='client-id']").text = opts.aad_client_id
                    properties.find("*/[@name='client-secret']").text = opts.aad_client_secret
                    properties.find("*/[@name='cluster-id']").text = opts.cluster_tag
            print("Updated discovery strategy nodes...")
        
            tree.write(opts.filename)
            print("Updating configuration file suceeded , file updated and saved at " + opts.filename)
        except IOError as e:
            print("Unable to open configuration file, I/O error ({0}) : {1}".format(e.errno, e.strerror))
                   
    else:
        print("Script exited without executing, no input parameters found")
        

   
    

