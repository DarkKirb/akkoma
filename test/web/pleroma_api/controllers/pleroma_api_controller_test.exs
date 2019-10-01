# Pleroma: A lightweight social networking server
# Copyright © 2017-2019 Pleroma Authors <https://pleroma.social/>
# SPDX-License-Identifier: AGPL-3.0-only

defmodule Pleroma.Web.PleromaAPI.PleromaAPIControllerTest do
  use Pleroma.Web.ConnCase

  alias Pleroma.Conversation.Participation
  alias Pleroma.Notification
  alias Pleroma.Repo
  alias Pleroma.Web.CommonAPI

  import Pleroma.Factory

  test "/api/v1/pleroma/conversations/:id", %{conn: conn} do
    user = insert(:user)
    other_user = insert(:user)

    {:ok, _activity} =
      CommonAPI.post(user, %{"status" => "Hi @#{other_user.nickname}!", "visibility" => "direct"})

    [participation] = Participation.for_user(other_user)

    result =
      conn
      |> assign(:user, other_user)
      |> get("/api/v1/pleroma/conversations/#{participation.id}")
      |> json_response(200)

    assert result["id"] == participation.id |> to_string()
  end

  test "/api/v1/pleroma/conversations/:id/statuses", %{conn: conn} do
    user = insert(:user)
    other_user = insert(:user)
    third_user = insert(:user)

    {:ok, _activity} =
      CommonAPI.post(user, %{"status" => "Hi @#{third_user.nickname}!", "visibility" => "direct"})

    {:ok, activity} =
      CommonAPI.post(user, %{"status" => "Hi @#{other_user.nickname}!", "visibility" => "direct"})

    [participation] = Participation.for_user(other_user)

    {:ok, activity_two} =
      CommonAPI.post(other_user, %{
        "status" => "Hi!",
        "in_reply_to_status_id" => activity.id,
        "in_reply_to_conversation_id" => participation.id
      })

    result =
      conn
      |> assign(:user, other_user)
      |> get("/api/v1/pleroma/conversations/#{participation.id}/statuses")
      |> json_response(200)

    assert length(result) == 2

    id_one = activity.id
    id_two = activity_two.id
    assert [%{"id" => ^id_one}, %{"id" => ^id_two}] = result
  end

  test "PATCH /api/v1/pleroma/conversations/:id", %{conn: conn} do
    user = insert(:user)
    other_user = insert(:user)

    {:ok, _activity} = CommonAPI.post(user, %{"status" => "Hi", "visibility" => "direct"})

    [participation] = Participation.for_user(user)

    participation = Repo.preload(participation, :recipients)

    assert [user] == participation.recipients
    assert other_user not in participation.recipients

    result =
      conn
      |> assign(:user, user)
      |> patch("/api/v1/pleroma/conversations/#{participation.id}", %{
        "recipients" => [user.id, other_user.id]
      })
      |> json_response(200)

    assert result["id"] == participation.id |> to_string

    [participation] = Participation.for_user(user)
    participation = Repo.preload(participation, :recipients)

    assert user in participation.recipients
    assert other_user in participation.recipients
  end

  describe "POST /api/v1/pleroma/notifications/read" do
    test "it marks a single notification as read", %{conn: conn} do
      user1 = insert(:user)
      user2 = insert(:user)
      {:ok, activity1} = CommonAPI.post(user2, %{"status" => "hi @#{user1.nickname}"})
      {:ok, activity2} = CommonAPI.post(user2, %{"status" => "hi @#{user1.nickname}"})
      {:ok, [notification1]} = Notification.create_notifications(activity1)
      {:ok, [notification2]} = Notification.create_notifications(activity2)

      response =
        conn
        |> assign(:user, user1)
        |> post("/api/v1/pleroma/notifications/read", %{"id" => "#{notification1.id}"})
        |> json_response(:ok)

      assert %{"pleroma" => %{"is_seen" => true}} = response
      assert Repo.get(Notification, notification1.id).seen
      refute Repo.get(Notification, notification2.id).seen
    end

    test "it marks multiple notifications as read", %{conn: conn} do
      user1 = insert(:user)
      user2 = insert(:user)
      {:ok, _activity1} = CommonAPI.post(user2, %{"status" => "hi @#{user1.nickname}"})
      {:ok, _activity2} = CommonAPI.post(user2, %{"status" => "hi @#{user1.nickname}"})
      {:ok, _activity3} = CommonAPI.post(user2, %{"status" => "HIE @#{user1.nickname}"})

      [notification3, notification2, notification1] = Notification.for_user(user1, %{limit: 3})

      [response1, response2] =
        conn
        |> assign(:user, user1)
        |> post("/api/v1/pleroma/notifications/read", %{"max_id" => "#{notification2.id}"})
        |> json_response(:ok)

      assert %{"pleroma" => %{"is_seen" => true}} = response1
      assert %{"pleroma" => %{"is_seen" => true}} = response2
      assert Repo.get(Notification, notification1.id).seen
      assert Repo.get(Notification, notification2.id).seen
      refute Repo.get(Notification, notification3.id).seen
    end

    test "it returns error when notification not found", %{conn: conn} do
      user1 = insert(:user)

      response =
        conn
        |> assign(:user, user1)
        |> post("/api/v1/pleroma/notifications/read", %{"id" => "22222222222222"})
        |> json_response(:bad_request)

      assert response == %{"error" => "Cannot get notification"}
    end
  end
end