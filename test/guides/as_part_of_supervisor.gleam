import chip
import gleam/erlang/process
import gleam/otp/actor
import gleam/otp/static_supervisor as supervisor
import gleam/otp/supervision

pub fn main() {
  let self = process.new_subject()
  let assert Ok(_supervisor) = supervisor(self)

  // Once initialized, the supervisor function will send back a message
  // with the child registry. From then we can use the registry to
  // find subjects.
  let assert Ok(registry) = process.receive(self, 500)
  let assert [_, _] = chip.members(registry, GroupA, 50)
  let assert [_, _] = chip.members(registry, GroupB, 50)
  let assert [_] = chip.members(registry, GroupC, 50)
}

// ------ Supervision Tree ------ //

// The tree is defined by calling a hierarchy of specifications
fn supervisor(main: process.Subject(Registry)) {
  let registry = chip.start(chip.Named("sessions"))
  let assert Ok(registry_subject) = registry
  supervisor.new(supervisor.OneForOne)
  |> supervisor.add(supervision.worker(fn() { registry }))
  |> supervisor.add(session_spec(registry_subject.data, GroupA))
  |> supervisor.add(session_spec(registry_subject.data, GroupB))
  |> supervisor.add(session_spec(registry_subject.data, GroupC))
  |> supervisor.add(session_spec(registry_subject.data, GroupA))
  |> supervisor.add(session_spec(registry_subject.data, GroupB))
  |> supervisor.add(ready(main, registry_subject.data))
  |> supervisor.start()
}

// ------ Registry ------ //

type Registry =
  chip.Registry(Message, Group)

// ------ Session ------- //

fn session_spec(registry: Registry, group: Group) {
  supervision.worker(fn() { start_session(registry, group) })
}

fn start_session(with registry: Registry, group group: Group) {
  // Mock function to startup a new session.
  case actor.new([]) |> actor.start() {
    Ok(session) -> {
      chip.register(registry, group, session.data)
      Ok(session)
    }
    Error(e) -> {
      Error(e)
    }
  }
}

// ------ Helpers ------ //

type Message =
  Nil

type Group {
  GroupA
  GroupB
  GroupC
}

fn ready(main: process.Subject(Registry), registry: Registry) {
  // This childspec is a noop addition to the supervisor, on return it
  // will send back the registry reference.
  supervision.worker(fn() {
    actor.new_with_initialiser(10, fn(self) {
      process.send(main, registry)

      let selector =
        process.new_selector()
        |> process.select(self)

      actor.initialised(Nil)
      |> actor.selecting(selector)
      |> Ok
    })
    |> actor.start()
  })
}
