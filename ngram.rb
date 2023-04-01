# frozen_string_literal: true

require 'yaml'

TOKEN_PATTERN = /
       ([A-Za-z']+) # words
     | ([.,!?]) # punctuation
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
  sum = tallies.reduce(0) do |s, (_, weight)|
    s + weight
  end
  tallies.transform_values do |weight|
    weight / sum.to_f
  end
end

def normalize_weights(tree)
  tree.reduce({}) do |h, (k, v)|
    if v.is_a?(Hash) && v.first[1].is_a?(Numeric)
      h.merge!(k => normalize_tallies(v))
    else
      h.merge!(k => normalize_weights(v))
    end
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

def build_ngram_tree(size, file)
  normalize_weights(generate_tree(ngrams(size, tokenize(IO.read(file))).tally))
end

def MAIN(file, n = nil)
  size = (n || 3).to_i
  puts build_ngram_tree(size, file).to_yaml
end

if $PROGRAM_NAME == __FILE__
  if ARGV.count < 1
    puts "Usage: #{$PROGRAM_NAME} FILE"
    exit 1
  end

  MAIN(ARGV[0], ARGV[1])
end
