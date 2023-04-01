# frozen_string_literal: true

require 'yaml'

TOKEN_PATTERN = /
     ([A-Za-z']+) # words
    | ([.,:!?]) # punctuation
    /x

def tokenize(string)
  string
    .scan(TOKEN_PATTERN)
    .lazy
    .flat_map(&:compact)
end

def ngrams(n, tokens)
  tokens.each_cons(n)
end

def normalize_tallies(tallies)
  max = tallies.values.max
  tallies.transform_values do |val|
    val.to_f / max
  end
end

class Hash
  def deep_merge(other_hash)
    merge(other_hash) do |key, this_val, other_val|
      if this_val.is_a?(Hash) && other_val.is_a?(Hash)
        this_val.deep_merge(other_val)
      else
        other_val
      end
    end
  end
end

def generate_tree(tallies)
  tallies.reduce({}) do |h, (ngram, score)|
    tree = {}
    scope = tree
    ngram.each_with_index do |token, i|
      if i == ngram.length - 1
        scope.merge!(token => score)
      else
        new = {}
        scope.merge!(token => new)
        scope = new
      end
    end

    h.deep_merge(tree)
  end
end

def MAIN(file)
  puts generate_tree(normalize_tallies(ngrams(2, tokenize(IO.read(file))).tally)).to_yaml
end

if ARGV.count < 1
  puts "Usage: #{$PROGRAM_NAME} FILE"
  exit 1
end

MAIN(ARGV[0])
