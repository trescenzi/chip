import chip
import gleam/erlang/process
import gleam/otp/actor
import gleam/otp/supervision as supervisor

type SessionRegistry =
  chip.Registry(Message, Int)

type Game =
  process.Subject(Message)

pub type Action {
  DrawCard
  PlayChip
  FireDice
}

pub opaque type Message {
  Next
  Current(client: process.Subject(String))
  Stop
}

pub type Session {
  Session(Int)
}

pub fn start(action) {
  actor.new(action)
  |> actor.on_message(loop)
  |> actor.start
}

pub fn start_with(id: Int, registry: SessionRegistry, action: Action) {
  let init = fn(self) { init(self, registry, id, action) }
  actor.new_with_initialiser(10, init)
  |> actor.on_message(loop)
  |> actor.start
}

pub fn childspec(id: Int, registry: SessionRegistry, action) {
  supervisor.worker(fn() { start_with(id, registry, action) })
}

pub fn next(game: Game) -> Nil {
  actor.send(game, Next)
}

pub fn current(game: Game) -> String {
  actor.call(game, 100, Current)
}

pub fn stop(game: Game) -> Nil {
  actor.send(game, Stop)
}

fn init(self, registry, id, action) {
  // Register the counter under an id on initialization
  chip.register(registry, id, self)

  // The registry may send messages through the self subject to this actor
  // adding self to this actor selector will allow us to handle those messages.
  let selector =
    process.new_selector()
    |> process.select(self)

  actor.initialised(action)
  |> actor.selecting(selector)
  |> actor.returning(self)
  |> Ok
}

fn loop(action, message) {
  case message {
    Next -> next_state(action)
    Current(client) -> send_unicode(client, action)
    Stop -> actor.stop()
  }
}

fn next_state(action) {
  actor.continue(case action {
    DrawCard -> PlayChip
    PlayChip -> FireDice
    FireDice -> DrawCard
  })
}

fn send_unicode(client, action) {
  process.send(client, case action {
    DrawCard -> "🂡"
    PlayChip -> "🪙"
    FireDice -> "🎲"
  })

  actor.continue(action)
}
