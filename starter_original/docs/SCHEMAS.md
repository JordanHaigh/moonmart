# Content data contract v0.1

`data/characters.json`: root `characters[]`, each with immutable `id`, display `name`, `role`, `prefers[]`, `storyline`.
`data/products.json`: root `products[]`, immutable `id`, display `name`, integer nonnegative `buy_price` and `sell_price`, `category`, `tags[]`.
`data/quests.json`: root `quests[]`, each with `id`, `title`, `objectives[]` containing `id` and `description`, `required_flags[]`, optional `next`.
`data/events.json`: root `events[]`, each with `id`, `type`, `min_shift`, `required_flags[]`, `priority`.

## Validation rules
IDs must be unique within type, snake_case ASCII. Cross-references must resolve. Prices and stock are integer quantities. Story flags default false. Do not use display names as stable save IDs. Event selection must be seeded and deterministic for test playback. These JSON files are authoring examples and are not yet wired into the simplified prototype's runtime.
