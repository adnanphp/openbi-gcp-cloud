# Pub/Sub

GCP's managed messaging service. Replaces Kafka (for simple event
flows) and SQS in the OpenBI deployment.

## Topics and subscriptions
openbi-events-PROJECT ← topic, producers publish here
│
▼
openbi-events-sub-PROJECT ← subscription, consumers pull here
│
│ (after 5 delivery attempts)
▼
openbi-events-dlq-PROJECT ← dead-letter topic
│
▼
openbi-events-dlq-sub-PROJECT ← DLQ subscription (required)

text

**Pub/Sub has no "queue" concept.** Only topics and subscriptions:

- A **topic** receives messages from publishers.
- A **subscription** delivers messages to subscribers.
- One subscription on a topic = work-queue pattern (one consumer per message).
- Multiple subscriptions on a topic = pub/sub fan-out (every subscription gets a copy).

OpenBI uses the single-subscription pattern.

## Configuration

| Setting | Value |
| --- | --- |
| Main topic | `openbi-events-PROJECT` |
| Main subscription | `openbi-events-sub-PROJECT` |
| Ack deadline | 60 seconds |
| Message retention | 7 days |
| DLQ topic | `openbi-events-dlq-PROJECT` |
| DLQ subscription | `openbi-events-dlq-sub-PROJECT` |
| Max delivery attempts before DLQ | 5 |

## Ack deadline vs. SQS visibility timeout

Both concepts do the same thing: hide a message from other consumers
while one is processing it. If the consumer doesn't ack within the
deadline, the message becomes visible again.

| GCP | AWS |
| --- | --- |
| Ack deadline (10–600s) | Visibility timeout (0–43,200s) |
| `acknowledge(ack_ids)` | `delete_message(ReceiptHandle)` |
| `modify_ack_deadline` | `change_message_visibility` |

GCP's window is shorter — Pub/Sub is designed for lower per-message
processing times. For longer jobs, use a lease-based approach.

## Dead-letter setup

The DLQ requires **two IAM bindings** on the Pub/Sub service agent
(the Google-managed SA that runs Pub/Sub forwarding):

- `roles/pubsub.publisher` on the DLQ topic
- `roles/pubsub.subscriber` on the main subscription

Without these, DLQ forwarding silently fails. The module creates them
automatically.

## Long polling

Pub/Sub pull is inherently long-polling — `pull()` waits up to the
request timeout for a message. Client libraries use streaming pull by
default, which is even more efficient.

**The pattern:** always set a bounded timeout on pull, always ack
immediately on success. Do not hold unacked messages longer than the
ack deadline.

## Publishing from Python

```python
from google.cloud import pubsub_v1

publisher = pubsub_v1.PublisherClient()
topic_path = publisher.topic_path(project_id, topic_name)

future = publisher.publish(
    topic_path,
    data=json.dumps(payload).encode("utf-8"),
    event_type="order.created",
)
message_id = future.result(timeout=30)
Consuming from Python
python
subscriber = pubsub_v1.SubscriberClient()
sub_path = subscriber.subscription_path(project_id, subscription_name)

response = subscriber.pull(request={"subscription": sub_path, "max_messages": 10})
for msg in response.received_messages:
    process(json.loads(msg.message.data))
    subscriber.acknowledge(
        request={"subscription": sub_path, "ack_ids": [msg.ack_id]}
    )
Always ack after success. Never ack before processing — if the ack
succeeds but processing fails, the message is gone.

Delivery guarantees
Pub/Sub provides at-least-once delivery (same as SQS). Consumers
must be idempotent — the same message may be delivered more than once.

Exactly-once is available with exactly_once_delivery = true on the
subscription, but it has throughput implications and is
not yet recommended for all workloads.

OpenBI uses at-least-once.

GCP vs AWS
GCP	AWS
Pub/Sub topic	SNS topic
Pub/Sub subscription	SQS queue (approximately)
Ack deadline	Visibility timeout
Ack ID	Receipt handle
Dead-letter topic	Dead-letter queue
Max delivery attempts	maxReceiveCount
Message retention	Message retention period (14 days max)
Streaming pull	Long polling
Message attribute	Message attribute
A subtle difference: in GCP, one topic can have multiple
subscriptions (each gets a copy — fan-out). In AWS, SQS and SNS are
separate services; fan-out requires an SNS topic with SQS queues
subscribed.

Verification status
Not verified against real GCP. Statically validated. See docs/verification.md.
