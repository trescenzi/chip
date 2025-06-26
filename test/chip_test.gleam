import artifacts/game.{DrawCard, FireDice, PlayChip}
import chip
import gleam/erlang/process
import gleam/list
import gleam/otp/actor
import gleam/otp/static_supervisor
import gleam/result
import gleeunit
import gleeunit/should

//*---------------- from tests -------------------*//

pub fn can_retrieve_a_named_registry_test() {
  let _ = chip.start(chip.Named("game-sessions"))
  let assert Ok(_) = chip.from("game-sessions")
}

pub fn cannot_retrieve_a_non_existing_registry_test() {
  let assert Error(Nil) = chip.from("non-existent")
}

pub fn can_retrieve_records_from_a_named_registry_test() {
  let assert Ok(registry) = chip.start(chip.Named("game-sessions"))
  let subject = registry.data

  let register = fn(session: actor.Started(process.Subject(game.Message))) {
    chip.register(subject, Nil, session.data)
  }

  let _ = game.start(DrawCard) |> result.map(register)
  let _ = game.start(DrawCard) |> result.map(register)
  let _ = game.start(DrawCard) |> result.map(register)

  let assert Ok(registry) = chip.from("game-sessions")
  let assert [_, _, _] = chip.members(registry, Nil, 50)
}

//*---------------- members tests -------------------*//

pub fn can_retrieve_subjects_from_group_test() {
  let assert Ok(registry) = chip.start(chip.Unnamed)
  let subject = registry.data

  let assert Ok(session_1) = game.start(DrawCard)
  let assert Ok(session_2) = game.start(DrawCard)
  let assert Ok(session_3) = game.start(DrawCard)
  let assert Ok(session_4) = game.start(DrawCard)
  let assert Ok(session_5) = game.start(DrawCard)
  let assert Ok(session_6) = game.start(DrawCard)

  session_1.data |> chip.register(subject, RoomA, _)
  session_2.data |> chip.register(subject, RoomB, _)
  session_3.data |> chip.register(subject, RoomB, _)
  session_4.data |> chip.register(subject, RoomC, _)
  session_5.data |> chip.register(subject, RoomC, _)
  session_6.data |> chip.register(subject, RoomC, _)

  let assert [_] = chip.members(subject, RoomA, 50)
  let assert [_, _] = chip.members(subject, RoomB, 50)
  let assert [_, _, _] = chip.members(subject, RoomC, 50)
}

pub fn can_retrieve_same_subject_from_different_groups_test() {
  let assert Ok(registry) = chip.start(chip.Unnamed)
  let subject = registry.data

  let assert Ok(session) = game.start(DrawCard)

  session.data |> chip.register(subject, RoomA, _)
  session.data |> chip.register(subject, RoomB, _)
  session.data |> chip.register(subject, RoomC, _)

  let assert [session_a] = chip.members(subject, RoomA, 50)
  let assert [session_b] = chip.members(subject, RoomB, 50)
  let assert [session_c] = chip.members(subject, RoomC, 50)
  should.be_true(session.data == session_a)
  should.be_true(session_a == session_b && session_b == session_c)
}

pub fn can_retrieve_individual_subjects_of_same_process_test() {
  let assert Ok(registry) = chip.start(chip.Unnamed)
  let subject = registry.data

  process.new_subject() |> chip.register(subject, Nil, _)
  process.new_subject() |> chip.register(subject, Nil, _)
  process.new_subject() |> chip.register(subject, Nil, _)

  let assert [_, _, _] = chip.members(subject, Nil, 50)
}

pub fn cannot_retrieve_duplicate_subjects_test() {
  let assert Ok(registry) = chip.start(chip.Unnamed)
  let subject = registry.data

  let self = process.new_subject()

  self |> chip.register(subject, Nil, _)
  self |> chip.register(subject, Nil, _)
  self |> chip.register(subject, Nil, _)

  let assert [_] = chip.members(subject, Nil, 50)
}

//*---------------- dispatch tests --------------*//

pub fn dispatch_is_applied_over_subjects_test() {
  let assert Ok(registry) = chip.start(chip.Unnamed)
  let subject = registry.data

  let assert Ok(session_1) = game.start(DrawCard)
  let assert Ok(session_2) = game.start(PlayChip)
  let assert Ok(session_3) = game.start(PlayChip)
  let assert Ok(session_4) = game.start(FireDice)
  let assert Ok(session_5) = game.start(FireDice)
  let assert Ok(session_6) = game.start(FireDice)

  session_1.data |> chip.register(subject, Nil, _)
  session_2.data |> chip.register(subject, Nil, _)
  session_3.data |> chip.register(subject, Nil, _)
  session_4.data |> chip.register(subject, Nil, _)
  session_5.data |> chip.register(subject, Nil, _)
  session_6.data |> chip.register(subject, Nil, _)

  chip.members(subject, Nil, 50)
  |> list.each(game.next)

  // wait for game session operation to finish
  let assert True =
    until(fn() { game.current(session_1.data) }, is: "🪙", for: 50)
  let assert True =
    until(fn() { game.current(session_2.data) }, is: "🎲", for: 50)
  let assert True =
    until(fn() { game.current(session_3.data) }, is: "🎲", for: 50)
  let assert True =
    until(fn() { game.current(session_4.data) }, is: "🂡", for: 50)
  let assert True =
    until(fn() { game.current(session_5.data) }, is: "🂡", for: 50)
  let assert True =
    until(fn() { game.current(session_6.data) }, is: "🂡", for: 50)
}

pub fn dispatch_is_applied_over_groups_test() {
  let assert Ok(registry) = chip.start(chip.Unnamed)
  let subject = registry.data

  let assert Ok(session_1) = game.start(DrawCard)
  let assert Ok(session_2) = game.start(DrawCard)
  let assert Ok(session_3) = game.start(DrawCard)
  let assert Ok(session_4) = game.start(DrawCard)
  let assert Ok(session_5) = game.start(DrawCard)
  let assert Ok(session_6) = game.start(DrawCard)

  session_1.data |> chip.register(subject, RoomA, _)
  session_2.data |> chip.register(subject, RoomB, _)
  session_3.data |> chip.register(subject, RoomB, _)
  session_4.data |> chip.register(subject, RoomC, _)
  session_5.data |> chip.register(subject, RoomC, _)
  session_6.data |> chip.register(subject, RoomC, _)

  chip.members(subject, RoomA, 50)
  |> list.each(game.next)

  chip.members(subject, RoomB, 50)
  |> list.each(fn(subject) {
    game.next(subject)
    game.next(subject)
  })

  chip.members(subject, RoomC, 50)
  |> list.each(fn(subject) {
    game.next(subject)
    game.next(subject)
    game.next(subject)
  })

  // wait for game session operation to finish
  let assert True =
    until(fn() { game.current(session_1.data) }, is: "🪙", for: 50)
  let assert True =
    until(fn() { game.current(session_2.data) }, is: "🎲", for: 50)
  let assert True =
    until(fn() { game.current(session_3.data) }, is: "🎲", for: 50)
  let assert True =
    until(fn() { game.current(session_4.data) }, is: "🂡", for: 50)
  let assert True =
    until(fn() { game.current(session_5.data) }, is: "🂡", for: 50)
  let assert True =
    until(fn() { game.current(session_6.data) }, is: "🂡", for: 50)
}

//*---------------- other tests ------------------*//

pub fn subject_eventually_deregisters_after_process_dies_test() {
  let assert Ok(registry) = chip.start(chip.Unnamed)

  let assert Ok(session) = game.start(DrawCard)
  chip.register(registry.data, "my-game", session.data)

  // stops the game session actor
  game.stop(session.data)

  // eventually the game session should be automatically de-registered
  let find = fn() { chip.members(registry.data, "my-game", 50) }
  let assert True = until(find, is: [], for: 50)
}

pub fn registering_works_along_supervisor_test() {
  let assert Ok(registry) = chip.start(chip.Unnamed)
  let subject = registry.data

  let _supervisor =
    static_supervisor.new(static_supervisor.OneForOne)
    |> static_supervisor.add(game.childspec(1, subject, DrawCard))
    |> static_supervisor.add(game.childspec(2, subject, PlayChip))
    |> static_supervisor.add(game.childspec(3, subject, FireDice))
    |> static_supervisor.start()

  // assert we can retrieve individual subjects
  let assert [session_1] = chip.members(subject, 1, 50)
  let assert "🂡" = game.current(session_1)

  let assert [session_2] = chip.members(subject, 2, 50)
  let assert "🪙" = game.current(session_2)

  let assert [session_3] = chip.members(subject, 3, 50)
  let assert "🎲" = game.current(session_3)

  // assert we're not able to retrieve non-registered subjects
  let assert [] = chip.members(subject, 4, 50)

  // assert subject is restarted by the supervisor after actor dies
  game.stop(session_2)

  let different_subject = fn() {
    case chip.members(subject, 2, 50) {
      [session] if session != session_2 -> True
      _other -> False
    }
  }

  let assert True = until(different_subject, is: True, for: 50)
}

//*---------------- Test helpers ----------------*//

pub fn main() {
  gleeunit.main()
}

type Room {
  RoomA
  RoomB
  RoomC
}

fn until(condition, is outcome, for milliseconds) -> Bool {
  case milliseconds, condition() {
    _milliseconds, result if result == outcome -> {
      True
    }

    milliseconds, _result if milliseconds > 0 -> {
      process.sleep(5)
      until(condition, outcome, milliseconds - 5)
    }

    _milliseconds, _result -> {
      False
    }
  }
}
