################################################################################
#
# Copyright (C) 2006 Peter J Jones (pjones@pmade.com)
#
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
# 
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#
################################################################################
class PDF::Reader
  ################################################################################
  class Buffer
    ################################################################################
    def initialize (io)
      @io = io
      @buffer = nil
    end
    ################################################################################
    def seek (offset)
      @io.seek(offset, IO::SEEK_SET)
      @buffer = nil
      self
    end
    ################################################################################
    def read (length)
      out = ""

      if @buffer and !@buffer.empty?
        out << head(length)
        length -= out.length
      end

      out << @io.read(length) if length > 0
      out
    end
    ################################################################################
    def eof?
      if @buffer
        @buffer.empty? && @io.eof?
      else
        @io.eof?
      end
    end
    ################################################################################
    def pos
      @io.pos
    end
    ################################################################################
    def ready_token (with_strip=true, skip_blanks=true)
      while @buffer.nil? or @buffer.empty?
        @buffer = @io.readline
        @buffer.sub!(/%.*$/, '')
        @buffer.chomp!
        @buffer.lstrip! if with_strip
        break unless skip_blanks
      end
    end
    ################################################################################
    def token
      ready_token

      i = @buffer.index(/[\[\]()<>{}\s\/]/) || @buffer.size

      token_chars = 
        if i == 0 and @buffer[i,2] == "<<"    : 2
        elsif i == 0 and @buffer[i,2] == ">>" : 2
        elsif i == 0                          : 1
        else                                    i
        end

      strip_space = !(i == 0 and @buffer[0,1] == '(')
      head(token_chars, strip_space)
    end
    ################################################################################
    def head (chars, with_strip=true)
      val = @buffer[0, chars]
      @buffer = @buffer[chars .. -1] || ""
      @buffer.lstrip! if with_strip
      val
    end
    ################################################################################
    def raw
      @buffer
    end
    ################################################################################
    def find_first_xref_offset
      @io.seek(-1024, IO::SEEK_END) rescue seek(0)
      data = @io.read(1024)
      lines = data.split(/\n/).reverse

      eof_index = nil

      lines.each_with_index do |line, index|
        if line =~ /^%%EOF\r?$/
          eof_index = index
          break
        end
      end

      raise "PDF does not contain EOF marker" if eof_index.nil?
      raise "PDF EOF marker does not follow offset" if eof_index >= lines.size-1
      lines[eof_index+1].to_i
    end
    ################################################################################
  end
  ################################################################################
end
################################################################################