class FakerTitle
  def title
    adjective = Faker::Adjective.unique.positive.capitalize
    faker_names = [
      Faker::Creature::Animal.name,
      Faker::Games::Overwatch.hero,
      Faker::Games::Control.altered_item,
      Faker::Games::Control.character,
      Faker::Games::Control.object_of_power,
      Faker::Games::Fallout.character,
      Faker::Games::LeagueOfLegends.champion,
      Faker::Games::WorldOfWarcraft.hero,
      Faker::Games::Witcher.monster,
      Faker::Games::Witcher.character,
      Faker::Games::Witcher.witcher,
      Faker::Games::HalfLife.character,
      Faker::Games::HalfLife.enemy,
      Faker::Space.star,
      Faker::Space.constellation,
      Faker::Space.galaxy,
      Faker::Superhero.name
    ]

    name = faker_names.sample.camelize
    "#{adjective} #{name}"
  end
end