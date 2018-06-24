# frozen_string_literal: true

# Copyright (c) 2018, by Jiang Jinyang. <https://justjjy.com>
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


module Ciri
  class Chain

    # block header
    class Header
      include Ciri::RLP::Serializable

      schema [
               :parent_hash,
               :ommers_hash,
               :beneficiary,
               :state_root,
               :transactions_root,
               :receipts_root,
               :logs_bloom,
               {difficulty: Integer},
               {number: Integer},
               {gas_limit: Integer},
               {gas_used: Integer},
               {timestamp: Integer},
               :extra_data,
               :mix_hash,
               :nonce,
             ]

      # header hash
      def get_hash
        Utils.sha3(rlp_encode)
      end

      # mining_hash, used for mining
      def mining_hash
        Utils.sha3(rlp_encode skip_keys: [:mix_hash, :nonce])
      end

    end

  end
end