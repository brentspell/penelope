defmodule Penelope.NLP.IntentClassifier do
  @moduledoc """
  The intent classifier transforms a natural language utterance into a
  named intent and a set of named parameters. It uses an ML classifier
  to infer the intent name and an entity recognizer to extract named
  entities as parameters. These components are both represented as
  ML pipelines.

  The intent classifier also maintains a tokenizer pipeline for converting
  utterances into a list of tokens. This pipeline is executed first, and
  its results are run through the classifier/recognizer pipelines.

  Classification results are returned as a tuple of <intents, parameters>,
  where intents is the map of names to classification probabilities, and
  parameters is a name->value map. Intent names, parameter names and
  parameter values are all strings. Probabilities are all floats that should
  sum to 1.

  Example:
    pipeline = %{
      tokenizer: [{:ptb_tokenizer, []}],
      classifier: [{:count_vectorizer, []},
                   {:linear_classifier, [c: 2.0, probability?: true]}],
      recognizer: [{:crf_tagger, []}],
    }
    x = [
      "you have four pears",
      "three hundred apples would be a lot"
    ]
    y = [
      {"intent_1", ["o", "o", "b_count", "b_fruit"]},
      {"intent_2", ["b_count", "i_count", "b_fruit", "o", "o", "o", "o"]}
    ]
    classifier = Penelope.NLP.IntentClassifier.fit(%{}, x, y, pipeline)

    {intents, params} = Penelope.NLP.IntentClassifier.predict_intent(
      classifier,
      %{},
      "I have three bananas"
    )
  """

  alias Penelope.ML.Pipeline

  @type model :: %{
          tokenizer: [{atom, any}],
          detokenizer: [{atom, any}],
          classifier: [{atom, any}],
          recognizer: [{atom, any}]
        }

  @doc """
  fits the tokenizer, classifier, and recognizer models
  """
  @spec fit(
          context :: map,
          x :: [utterance :: String.t()],
          y :: [{intent :: String.t(), tags :: [String.t()]}],
          pipelines :: [
            tokenizer: [{String.t() | atom, any}],
            classifier: [{String.t() | atom, any}],
            recognizer: [{String.t() | atom, any}]
          ]
        ) :: model
  def fit(context, x, y, pipelines) do
    pipelines = Map.new(pipelines)

    tokenizer = Pipeline.fit(context, x, y, pipelines.tokenizer)
    x_token = Pipeline.transform(tokenizer, context, x)

    {y_intent, y_entity} = Enum.unzip(y)

    classifier =
      Pipeline.fit(context, x_token, y_intent, pipelines.classifier)

    recognizer =
      Pipeline.fit(context, x_token, y_entity, pipelines.recognizer)

    %{
      tokenizer: tokenizer,
      detokenizer: Enum.reverse(tokenizer),
      classifier: classifier,
      recognizer: recognizer
    }
  end

  @doc """
  predicts an intent and its parameters from an utterance string
  """
  @spec predict_intent(
          model :: model,
          context :: map,
          x :: String.t()
        ) ::
          {intents :: %{(intent :: String.t()) => probability :: float},
           params :: %{(name :: String.t()) => value :: String.t()}}
  def predict_intent(model, context, x) do
    # tokenize the utterance
    [tokens] = Pipeline.transform(model.tokenizer, context, [x])

    # predict the intent probabilities
    [intents] =
      Pipeline.predict_probability(model.classifier, context, [tokens])

    # predict the tag sequence
    {intent, _probability} = Enum.max_by(intents, fn {_, v} -> v end)
    context = Map.put(context, :intent, intent)

    [{tags, _probability}] =
      Pipeline.predict_sequence(model.recognizer, context, [tokens])

    # detokenize the parameters
    params = parse(tokens, tags)

    params =
      Map.new(params, fn {k, v} ->
        [v] = Pipeline.transform(model.detokenizer, context, [v])
        {k, v}
      end)

    {intents, params}
  end

  # parse IOB tags
  # ignore tokens tagged as "o" (other)
  # strip the leading b_/i_ from tag names
  # merge consecutive tagged tokens into lists for detokenization
  # combine tokens with the same name under that key in the map
  defp parse([], []) do
    %{}
  end

  defp parse([_token | tokens], ["o" | tags]) do
    parse(tokens, tags)
  end

  defp parse([token | tokens], [tag | tags]) do
    <<_bi, __>> <> name = tag

    params = parse(tokens, tags)
    Map.update(params, name, [token], &[token | &1])
  end

  @doc """
  imports parameters from a serialized model
  """
  @spec compile(params :: map) :: model
  def compile(params) do
    tokenizer = Pipeline.compile(params["tokenizer"])

    %{
      tokenizer: tokenizer,
      detokenizer: Enum.reverse(tokenizer),
      classifier: Pipeline.compile(params["classifier"]),
      recognizer: Pipeline.compile(params["recognizer"])
    }
  end

  @doc """
  exports a runtime model to a serializable data structure
  """
  @spec export(model :: model) :: map
  def export(model) do
    %{
      "tokenizer" => Pipeline.export(model.tokenizer),
      "classifier" => Pipeline.export(model.classifier),
      "recognizer" => Pipeline.export(model.recognizer)
    }
  end
end
