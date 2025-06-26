import chip
import gleam/erlang/process
import gleam/otp/supervision

pub type Store(message) =
  chip.Registry(message, Int)

pub type Id =
  Int

pub fn start() {
  chip.start(chip.Unnamed)
}

pub fn childspec() {
  supervision.worker(start)
}

pub fn index(store: Store(message), id: Id, subject: process.Subject(message)) {
  chip.register(store, id, subject)
}

pub fn get(store: Store(message), id: Id) {
  case chip.members(store, id, 50) {
    [] -> Error(Nil)
    [subject] -> Ok(subject)
    [_, ..] -> panic as "Shouldn't insert more than 1 subject."
  }
}
