# Pleroma: A lightweight social networking server

# Copyright © 2017-2021 Pleroma Authors <https://pleroma.social/>
# SPDX-License-Identifier: AGPL-3.0-only

defmodule Pleroma.Web.Metadata.Providers.TwitterCard do
  alias Pleroma.User
  alias Pleroma.Web.MediaProxy
  alias Pleroma.Web.Metadata
  alias Pleroma.Web.Metadata.Providers.Provider
  alias Pleroma.Web.Metadata.Utils

  use Pleroma.Web, :verified_routes

  @behaviour Provider
  @media_types ["image", "audio", "video"]

  @impl Provider
  def build_tags(%{activity_id: id, object: object, user: user}) do
    attachments =
      if Utils.visible?(object) do
        build_attachments(id, object)
      else
        []
      end

    scrubbed_content =
      if Utils.visible?(object) do
        Utils.scrub_html_and_truncate(object)
      else
        "Content cannot be displayed."
      end

    [
      {:meta,
        [
          property: "twitter:card",
          content: "summary"
        ], []},
      {:meta,
       [
         property: "twitter:title",
         content: Utils.user_name_string(user)
       ], []},
      {:meta, [property: "twitter:url", content: url], []},
      {:meta,
       [
         property: "twitter:description",
         content: scrubbed_content
       ], []},
      {:meta, [property: "twitter:type", content: "article"], []}
    ] ++
      if attachments == [] or Metadata.activity_nsfw?(object) do
        [
          {:meta, [property: "twitter:image", content: MediaProxy.preview_url(User.avatar_url(user))],
           []},
          {:meta, [property: "twitter:image:width", content: 150], []},
          {:meta, [property: "twitter:image:height", content: 150], []}
        ]
      else
        attachments
      end
  end

  @impl Provider
  def build_tags(%{user: user}) do
    if Utils.visible?(user) do
      with truncated_bio = Utils.scrub_html_and_truncate(user.bio) do
        [
          title_tag(user),
          {:meta, [name: "twitter:description", content: truncated_bio], []},
          image_tag(user),
          {:meta, [name: "twitter:card", content: "summary"], []}
        ]
      end
    else
      []
    end
  end

  defp title_tag(user) do
    {:meta, [name: "twitter:title", content: Utils.user_name_string(user)], []}
  end

  def image_tag(user) do
    if Utils.visible?(user) do
      {:meta, [name: "twitter:image", content: MediaProxy.preview_url(User.avatar_url(user))], []}
    else
      {:meta, [name: "twitter:image", content: ""], []}
    end
  end

  defp build_attachments(id, %{data: %{"attachment" => attachments}}) do
    Enum.reduce(attachments, [], fn attachment, acc ->
      rendered_tags =
        Enum.reduce(attachment["url"], [], fn url, acc ->
          # TODO: Whatsapp only wants JPEG or PNGs. It seems that if we add a second twitter:image
          # object when a Video or GIF is attached it will display that in Whatsapp Rich Preview.
          case Utils.fetch_media_type(@media_types, url["mediaType"]) do
            "audio" ->
              [
                {:meta, [property: "twitter:audio", content: MediaProxy.url(url["href"])], []}
                | acc
              ]

            # Not using preview_url for this. It saves bandwidth, but the image dimensions will
            # be wrong. We generate it on the fly and have no way to capture or analyze the
            # image to get the dimensions. This can be an issue for apps/FEs rendering images
            # in timelines too, but you can get clever with the aspect ratio metadata as a
            # workaround.
            "image" ->
              [
                {:meta, [property: "twitter:image", content: MediaProxy.url(url["href"])], []},
                {:meta, [property: "twitter:image:alt", content: attachment["name"]], []}
                | acc
              ]
              |> maybe_add_dimensions(url)

            "video" ->
              [
                {:meta, [property: "twitter:video", content: MediaProxy.url(url["href"])], []}
                | acc
              ]
              |> maybe_add_dimensions(url)
              |> maybe_add_video_thumbnail(url)

            _ ->
              acc
          end
        end)

      acc ++ rendered_tags
    end)
  end

  defp build_attachments(_), do: []

  # We can use url["mediaType"] to dynamically fill the metadata
  defp maybe_add_dimensions(metadata, url) do
    type = url["mediaType"] |> String.split("/") |> List.first()

    cond do
      !is_nil(url["height"]) && !is_nil(url["width"]) ->
        metadata ++
          [
            {:meta, [property: "twitter:#{type}:width", content: "#{url["width"]}"], []},
            {:meta, [property: "twitter:#{type}:height", content: "#{url["height"]}"], []}
          ]

      true ->
        metadata
    end
  end

  # Media Preview Proxy makes thumbnails of videos without resizing, so we can trust the
  # width and height of the source video.
  defp maybe_add_video_thumbnail(metadata, url) do
    cond do
      Pleroma.Config.get([:media_preview_proxy, :enabled], false) ->
        metadata ++
          [
            {:meta, [property: "twitter:image:width", content: "#{url["width"]}"], []},
            {:meta, [property: "twitter:image:height", content: "#{url["height"]}"], []},
            {:meta, [property: "twitter:image", content: MediaProxy.preview_url(url["href"])], []}
          ]

      true ->
        metadata
    end
  end
end
