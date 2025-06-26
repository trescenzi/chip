import chip
import gleam/erlang/process
import gleam/otp/actor

pub opaque type Message {
  Inc
  Current(client: process.Subject(Int))
  Stop
}

pub type Group {
  GroupA
  GroupB
  GroupC
}

pub fn start(registry: chip.Registry(Message, Group), group: Group, count: Int) {
  let init = fn(self) { init(self, registry, group, count) }
  actor.new_with_initialiser(10, init)
  |> actor.on_message(loop)
  |> actor.start()
}

pub fn stop(counter: process.Subject(Message)) -> Nil {
  actor.send(counter, Stop)
}

pub fn increment(counter: process.Subject(Message)) -> Nil {
  actor.send(counter, Inc)
}

pub fn current(counter: process.Subject(Message)) -> Int {
  actor.call(counter, 10, Current)
}

fn init(self, registry: chip.Registry(Message, Group), group: Group, count: Int) {
  // Register the counter under an id on initialization
  chip.register(registry, group, self)

  let selector =
    process.new_selector()
    |> process.select(self)

  // The registry may send messages through the self subject to this actor
  // adding self to this actor selector will allow us to handle those messages.

  actor.initialised(count) 
  |> actor.selecting(selector)
  |> actor.returning(self)
  |> Ok
}

fn loop(count: Int, message: Message) {
  case message {
    Inc -> {
      actor.continue(count + 1)
    }

    Current(client) -> {
      process.send(client, count)
      actor.continue(count)
    }

    Stop -> {
      actor.stop()
    }
  }
}
