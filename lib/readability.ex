defmodule Readability do
  @moduledoc """
  Readability library for extracting & curating articles.

  ## Example

  ```elixir
  @type html :: binary

  # Just pass url
  %Readability.Summary{title: title, authors: authors, article_html: article} = Readability.summarize(url)

  # Extract title
  Readability.title(html)

  # Extract authors.
  Readability.authors(html)

  # Extract only text from article
  article = html
            |> Readability.article
            |> Readability.readable_text

  # Extract article with transformed html
  article = html
            |> Readability.article
            |> Readability.raw_html
  ```
  """

  alias Readability.TitleFinder
  alias Readability.AuthorFinder
  alias Readability.ArticleBuilder
  alias Readability.Summary
  alias Readability.Helper

  @default_options [
    retry_length: 250,
    min_text_length: 25,
    remove_unlikely_candidates: true,
    weight_classes: true,
    clean_conditionally: true,
    remove_empty_nodes: true,
    min_image_width: 130,
    min_image_height: 80,
    ignore_image_format: [],
    blacklist: nil,
    whitelist: nil,
    page_url: nil
  ]

  @regexes [
    unlikely_candidate:
      ~r/combx|comment|community|disqus|extra|foot|header|hidden|lightbox|modal|menu|meta|nav|remark|rss|shoutbox|sidebar|sponsor|ad-break|agegate|pagination|pager|popup/i,
    ok_maybe_its_a_candidate: ~r/and|article|body|column|main|shadow/i,
    positive: ~r/article|body|content|entry|hentry|main|page|pagination|post|text|blog|story/i,
    negative:
      ~r/hidden|^hid|combx|comment|com-|contact|foot|footer|footnote|link|masthead|media|meta|outbrain|promo|related|scroll|shoutbox|sidebar|sponsor|shopping|tags|tool|utility|widget/i,
    div_to_p_elements: ~r/<(a|blockquote|dl|div|img|ol|p|pre|table|ul)/i,
    replace_brs: ~r/(<br[^>]*>[ \n\r\t]*){2,}/i,
    replace_fonts: ~r/<(\/?)font[^>]*>/i,
    replace_xml_version: ~r/<\?xml.*\?>/i,
    normalize: ~r/\s{2,}/,
    video: ~r/\/\/(www\.)?(dailymotion|youtube|youtube-nocookie|player\.vimeo)\.com/i,
    protect_attrs: ~r/^(?!id|rel|for|summary|title|href|src|alt|srcdoc)/i,
    img_tag_src: ~r/(<img.*src=['"])([^'"]+)(['"][^>]*>)/Ui
  ]

  @markup_mimes ~r/^(application|text)\/[a-z\-_\.\+]+ml(;\s*charset=.*)?$/i

  @type html_tree :: tuple | list
  @type raw_html :: binary
  @type url :: binary
  @type options :: list
  @type headers :: list[tuple]

  @doc """
  Extract MIME Type from headers

  ## Example

      iex> mime = Readability.mime(headers_list)
      "text/html"
  """
  @spec mime(headers) :: String.t()
  def mime(headers \\ []) do
    headers
    |> Enum.find(
      # default
      {"Content-Type", "text/plain"},
      fn {key, _} -> String.downcase(key) == "content-type" end
    )
    |> elem(1)
  end

  @doc """
  Return true if Content-Type in provided headers list is a markup type,
  else false

  ## Example

      iex> Readability.is_response_markup?([{"Content-Type", "text/html"}])
      true
  """
  @spec is_response_markup(headers) :: boolean
  def is_response_markup(headers) do
    mime(headers) =~ @markup_mimes
  end

  @doc """
  Extract title

  ## Example

      iex> title = Readability.title(html_str)
      "Some title in html"
  """
  @spec title(binary | html_tree) :: binary
  def title(raw_html) when is_binary(raw_html) do
    raw_html
    |> Helper.normalize()
    |> title
  end

  def title(html_tree), do: TitleFinder.title(html_tree)

  @doc """
  Extract authors

  ## Example

      iex> authors = Readability.authors(html_str)
      ["José Valim", "chrismccord"]
  """
  @spec authors(binary | html_tree) :: list[binary]
  def authors(html) when is_binary(html), do: html |> parse |> authors
  def authors(html_tree), do: AuthorFinder.find(html_tree)

  @doc """
  Using a variety of metrics (content score, classname, element types), find the content that is
  most likely to be the stuff a user wants to read

  ## Example

      iex> article_tree = Redability(html_str)
      # returns article that is tuple

  """
  @spec article(binary, options) :: html_tree
  def article(raw_html, opts \\ []) do
    opts = Keyword.merge(@default_options, opts)

    raw_html
    |> Helper.normalize()
    |> ArticleBuilder.build(opts)
  end

  @doc """
  return attributes, tags cleaned html
  """
  @spec readable_html(html_tree) :: binary
  def readable_html(html_tree) do
    html_tree
    |> Helper.remove_attrs(regexes(:protect_attrs))
    |> raw_html
  end

  @doc """
  return only text binary from html_tree
  """
  @spec readable_text(html_tree) :: binary
  def readable_text(html_tree) do
    # TODO: Remove image caption when extract only text
    tags_to_br = ~r/<\/(p|div|article|h\d)/i
    html_str = html_tree |> raw_html

    Regex.replace(tags_to_br, html_str, &"\n#{&1}")
    |> Floki.parse_document!()
    |> Floki.text()
    |> String.trim()
  end

  @doc """
  return raw html binary from html_tree
  """
  @spec raw_html(html_tree) :: binary
  def raw_html(html_tree) do
    html_tree |> Floki.raw_html(encode: false)
  end

  def parse(raw_html) when is_binary(raw_html) do
    {:ok, document} = Floki.parse_document(raw_html)
    document
  end

  def regexes(key), do: @regexes[key]

  def default_options, do: @default_options
end
