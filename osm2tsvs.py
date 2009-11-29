#! /usr/bin/python
# -* encoding: utf8 -*-

import xml.sax
import sys, gzip

# files
nodes = gzip.open("nodes.tsv.gz", "w")
node_tags = gzip.open("node_tags.tsv.gz", "w")
ways = gzip.open("ways.tsv.gz", "w")
way_tags = gzip.open("way_tags.tsv.gz", "w")
way_nodes = gzip.open("way_nodes.tsv.gz", "w")
relations = gzip.open("relations.tsv.gz", "w")
relation_tags = gzip.open("relation_tags.tsv.gz", "w")
relation_members = gzip.open("relation_members.tsv.gz", "w")

def tab(values):
    values = [unicode(x).replace("\t", "\\t") for x in values]
    return ("\t".join(values) + "\n").encode("utf8")

class OSMtoTSV(xml.sax.ContentHandler):
    id = None
    node_offset = None
    member_offset = None

    def startElement(self, name, attrs):
        func_name = "start_%s" % name
        if hasattr(self, func_name) and  callable(getattr(self, func_name)):
            getattr(self, func_name)(attrs)


    def start_node(self, attrs):
        nodes.write(tab([attrs.get(x, "NULL") for x in ('id', 'timestamp', 'user', 'lat', 'lon')]))
        self.id = attrs['id']
        self.type = 'node'
    
    def end_node(self):
        self.type = None
        self.id = None

    def start_way(self, attrs):
        ways.write(tab([attrs.get(x, "NULL") for x in ('id', 'timestamp', 'user')]))
        self.id = attrs['id']
        self.type = "way"
        self.node_offset = 0

    def end_way(self):
        self.type = None
        self.node_offset = None
        self.id = None

    def start_tag(self, attrs):
        if self.type == 'node':
            node_tags.write(tab([self.id, attrs['k'], attrs['v']]))
        elif self.type == 'way':
            way_tags.write(tab([self.id, attrs['k'], attrs['v']]))
        elif self.type == 'relation':
            relation_tags.write(tab([self.id, attrs['k'], attrs['v']]))
        else:
            assert False, "Got a tag of %s" % self.type

    def start_nd(self, attrs):
        assert self.type == 'way'
        assert self.node_offset is not None
        way_nodes.write(tab([self.id, self.node_offset, attrs['ref']]))
        self.node_offset += 1

    def start_relation(self, attrs):
        relations.write(tab([attrs.get(x, "NULL") for x in ('id', 'timestamp', 'user')]))
        self.type = "relation"
        self.id = attrs['id']
        self.member_offset = 0

    def end_relation(self):
        self.id = None
        self.type = None
        self.member_offset = None

    def start_member(self, attrs):
        assert self.member_offset is not None
        relation_members.write(tab([self.id, attrs['type'], attrs['ref'], attrs.get('role', "NULL"), self.member_offset]))
        self.member_offset += 1
        

    def endElement(self, name):
        func_name = "end_%s" % name
        if hasattr(self, func_name) and  callable(getattr(self, func_name)):
            getattr(self, func_name)()
        

xml.sax.parse(sys.stdin, OSMtoTSV())
