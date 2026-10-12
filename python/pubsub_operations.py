"""Pub/Sub operations via the Google Cloud Python SDK.

Demonstrates the patterns OpenBI uses for event-driven flows:
  1. Publish a message
  2. Subscribe (pull with wait)
  3. Acknowledge after successful processing
  4. Inspect the dead-letter subscription

Usage:
    export GOOGLE_CLOUD_PROJECT=your-project-id
    export OPENBI_PUBSUB_TOPIC=openbi-events-PROJECT
    export OPENBI_PUBSUB_SUBSCRIPTION=openbi-events-sub-PROJECT
    export OPENBI_PUBSUB_DLQ_SUB=openbi-events-dlq-sub-PROJECT
    python python/pubsub_operations.py

Requires:
    pip install google-cloud-pubsub
"""

from __future__ import annotations

import json
import os
import sys
import time
import uuid


def publish(client, topic_path: str, payload: dict) -> str:
    """Publish a JSON message. Returns the message ID."""
    data = json.dumps(payload).encode("utf-8")
    future = client.publish(topic_path, data, event_type=payload.get("event_type", "unknown"))
    return future.result(timeout=30)


def pull_one(client, subscription_path: str, timeout: float = 20.0) -> dict | None:
    """Pull a single message with a bounded wait."""
    from google.cloud import pubsub_v1

    response = client.pull(
        request={"subscription": subscription_path, "max_messages": 1},
        timeout=timeout,
    )
    if not response.received_messages:
        return None
    return response.received_messages[0]


def acknowledge(client, subscription_path: str, ack_id: str) -> None:
    """Acknowledge a successfully processed message."""
    client.acknowledge(
        request={"subscription": subscription_path, "ack_ids": [ack_id]}
    )


def main() -> int:
    project = os.environ.get("GOOGLE_CLOUD_PROJECT")
    topic_name = os.environ.get("OPENBI_PUBSUB_TOPIC")
    sub_name = os.environ.get("OPENBI_PUBSUB_SUBSCRIPTION")

    if not project or not topic_name or not sub_name:
        print("Set GOOGLE_CLOUD_PROJECT, OPENBI_PUBSUB_TOPIC, OPENBI_PUBSUB_SUBSCRIPTION.")
        print()
        print("The SDK patterns this script demonstrates:")
        print("  - publisher.publish(topic_path, data, **attributes)")
        print("  - subscriber.pull(subscription_path, max_messages=1)")
        print("  - subscriber.acknowledge(subscription_path, ack_ids=[...])")
        print()
        print("Note: Pub/Sub has no 'queue'. A single subscription on a topic")
        print("is the work-queue pattern. Ack deadline (10-600s) is the")
        print("equivalent of SQS visibility timeout.")
        return 0

    try:
        from google.cloud import pubsub_v1
    except ImportError:
        print("Install: pip install google-cloud-pubsub")
        return 1

    publisher = pubsub_v1.PublisherClient()
    subscriber = pubsub_v1.SubscriberClient()

    topic_path = publisher.topic_path(project, topic_name)
    sub_path = subscriber.subscription_path(project, sub_name)

    # --- Publish ---
    print("==> Publish")
    event = {
        "event_type": "order.created",
        "event_id": str(uuid.uuid4()),
        "order_id": 12345,
        "amount": 249.99,
    }
    msg_id = publish(publisher, topic_path, event)
    print(f"    published: {msg_id}")
    print(f"    body: {json.dumps(event)}")

    # --- Pull and ack ---
    print("\n==> Pull (wait up to 20s)")
    msg = pull_one(subscriber, sub_path)
    if msg is None:
        print("    (no message)")
    else:
        print(f"    ack_id: {msg.ack_id[:30]}...")
        print(f"    body:   {msg.message.data.decode('utf-8')}")
        print(f"    attrs:  {dict(msg.message.attributes)}")
        print("    acking...")
        acknowledge(subscriber, sub_path, msg.ack_id)
        print("    acked")

    return 0


if __name__ == "__main__":
    sys.exit(main())
