import artifacts/game.{DrawCard, FireDice, PlayChip}
import chip
import gleam/list

pub type Group {
  GroupA
  GroupB
}

pub fn main() {
  let assert Ok(registry) = chip.start(chip.Unnamed)

  let assert Ok(session_a) = game.start(DrawCard)
  let assert Ok(session_b) = game.start(FireDice)
  let assert Ok(session_c) = game.start(PlayChip)

  chip.register(registry.data, GroupA, session_a.data)
  chip.register(registry.data, GroupB, session_b.data)
  chip.register(registry.data, GroupA, session_c.data)

  chip.members(registry.data, GroupA, 50)
  |> list.each(fn(session) { game.next(session) })
}
