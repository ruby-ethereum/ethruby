# frozen_string_literal: true


# Copyright (c) 2018 by Jiang Jinyang <jjyruby@gmail.com>
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.


require 'async'
require 'ciri/utils/logger'
require_relative 'discovery'

module Ciri
  module DevP2P

    # implement the DiscV4 protocol
    # https://github.com/ethereum/devp2p/blob/master/discv4.md
    class DiscoveryService
      include Utils::Logger
      # use message classes defined in Discovery
      include Discovery

      #TODO implement peer_store
      # we should consider search from peer_store instead connect to bootnodes everytime 
      def initialize(host:, port:, bootnodes:[], discovery_interval_secs: 15)
        @bootnodes = bootnodes
        @discovery_interval_secs = discovery_interval_secs
        @cache = Set.new
        @host = host
        @port = port
        @known_peers = KnownPeers.new
      end

      # find outgoing peers, should return in order from higher score to lower
      # TODO consider implement this method in peerstore
      # TODO implement this
      def find_outgoing_peers(running_count, peers, now)
        node = @bootnodes.sample
        return [] if @cache.include?(node)
        @cache << node
        [node]
      end

      def run(task: Async::Task.current)
        # start listening
        task.async {start_listen}
        # search peers every x seconds
        task.reactor.every(@discovery_interval_secs) do
          perform_discovery
        end
      end

      private
      def start_listen(task: Async::Task.current)
        endpoint = Async::IO::Endpoint.udp(@host, @port)
        endpoint.bind do |socket|
          @local_address = socket.local_address
          debug "start discovery server on #{@local_address.getnameinfo.join(":")}"

          loop do
            # read discovery message
            packet, address = socket.recvfrom(Discovery::Message::MAX_LEN)
            handle_request(packet, address)
          end
        end
      end

      MESSAGE_EXPIRATION_IN = 10 * 60 # set 10 minutes later to expiration message

      # TODO consider implement a denylist to record bad nodes address
      def handle_request(raw_packet, address)
        msg = Message.decode_message(raw_packet)
        msg.validate
        if msg.packet.expiration < now
          trace("ignore expired message, sender: #{msg.sender}, expired_at: #{msg.packet.expiration}")
          return
        end
        case msg.packet_type
        when Ping::CODE
          # respond pong
          pong = Pong.new(to: To.from_inet_addr(address), 
                          ping_hash: msg.message_hash, 
                          expiration: Time.now.to_i + MESSAGE_EXPIRATION_IN)
          pong_msg = Message.pack(pong).encode_message
          socket.send(pong_msg, 0, address[3], address[1])
        when Pong::CODE
          # check pong
          unless @known_peers.has_ping?(msg.sender.to_bytes, msg.packet.ping_hash)
            # update peer last seen
            @kown_peers.update_last_seen(msg.sender.to_bytes)
          end
        when FindNode::CODE
          #TODO
          @kown_peers.update_last_seen(msg.sender.to_bytes)
        when Neighbors::CODE
          #TODO
          @kown_peers.update_last_seen(msg.sender.to_bytes)
        else
          # TODO add address to denylist
          raise UnknownMessageCodeError.new("can't handle unknown code in discovery protocol, code: #{msg.packet_type}")
        end
      rescue StandardError => e
        #TODO add address to denylist
        error("discovery error: #{e} from address: #{address}")
      end

      class KnownPeers
        PEER_LAST_SEEN_VALID = 12 * 3600 # 12 hour
        PING_EXPIRATION_IN = 10 * 60 # allow ping

        def initialize
          #TODO how to recycle memory?
          @peers = {}
        end
        
        def has_ping?(raw_node_id, ping_hash)
          #TODO
        end

        # record ping message
        def ping_to(raw_node_id, ping_hash, expired_at: Time.now.to_i + PING_EXPIRATION_IN)
          #TODO
        end

        def update_last_seen(raw_node_id, at: Time.now.to_i)
          @peers[raw_node_id] = at
        end

        def has_seen?(raw_node_id, in: PEER_LAST_SEEN_VALID)
          seen = (last_seen_at = @peers[raw_node_id]) && (last_seen_at + PEER_LAST_SEEN_VALID > Time.now.to_i)
          # convert to bool
          !!seen
        end
      end

      # find nerly neighbours
      def find_neighbours(raw_node_id)
        #TODO implement
      end

      def perform_discovery
        #TODO implement discovery nodes
      end
    end

  end
end
