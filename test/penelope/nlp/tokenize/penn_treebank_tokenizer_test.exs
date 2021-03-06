defmodule Penelope.NLP.Tokenize.PennTreebankTokenizerTest do
  @moduledoc false

  use ExUnit.Case
  alias Penelope.NLP.Tokenize.PennTreebankTokenizer, as: Tokenizer

  test "some sample tokenizations" do
    text = ~s(The quick, brown dog jumped over the "fence")

    expected = [
      "The",
      "quick",
      ",",
      "brown",
      "dog",
      "jumped",
      "over",
      "the",
      "``",
      "fence",
      "''"
    ]

    assert Tokenizer.tokenize(text) == expected
    text = "That costs $1.35."
    expected = ["That", "costs", "$", "1.35", "."]
    assert Tokenizer.tokenize(text) == expected
    assert Tokenizer.detokenize(expected) == text
    text = "What're you gonna do about it?"
    expected = ["What", "'re", "you", "gon", "na", "do", "about", "it", "?"]
    assert Tokenizer.tokenize(text) == expected
    assert Tokenizer.detokenize(expected) == text
    text = "I don't know!"
    expected = ["I", "do", "n't", "know", "!"]
    assert Tokenizer.tokenize(text) == expected
    assert Tokenizer.detokenize(expected) == text
    text = "fly {pronoun} to the moon"
    expected = ["fly", "{", "pronoun", "}", "to", "the", "moon"]
    assert Tokenizer.tokenize(text) == expected
    assert Tokenizer.detokenize(expected) == text
  end

  test "detokenization special cases" do
    tokens = ["Et", "tu", ",", "Brute", "?", "Yes", "."]
    expected = "Et tu, Brute? Yes."
    assert Tokenizer.detokenize(tokens) == expected
  end
end
