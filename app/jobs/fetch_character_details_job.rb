# frozen_string_literal: true

class FetchCharacterDetailsJob < ApplicationJob
  queue_as :default

  def perform(mem_id, type, _character, _data)
    # Make our request and get specific character data from it
    @request ||= api_get("https://www.bungie.net/Platform/Destiny2/#{type}/Profile/#{mem_id}/?components=Characters,205")
    @characters_data ||= JSON.parse(@request.body)
    character_data = {}

    @characters_data['Response']['characters']['data'].each do |char|
      id = char[0]

      light = char[1]['light']
      last_played = char[1]['dateLastPlayed']
      type = CHARACTER_CLASSES[char[1]['classType']]
      emblem = char[1]['emblemPath']
      bg = char[1]['emblemBackgroundPath']
      items = @characters_data['Response']['characterEquipment']['data'][id]['items']
      subclass_item = items.find { |item| item['bucketHash'] == 3_284_755_031 }
      subclass_name = SUBCLASSES[subclass_item['itemHash'].to_s]

      if !user.characters.find_by(character_id: id)
        @character = user.characters.build(character_id: id)
        @character.save!
        @char_data = @character.character_details.build(
          character_type: type,
          subclass: subclass_name,
          light_level: light,
          emblem: "https://www.bungie.net#{emblem}",
          emblem_background: "https://www.bungie.net#{bg}",
          last_login: last_played
        )

        @char_data.save!
      else
        @character = user.characters.find_by(character_id: id)
        if @character.character_details == []
          @details = @character.character_details.build(
            character_type: type,
            subclass: subclass_name,
            light_level: light,
            emblem: "https://www.bungie.net#{emblem}",
            emblem_background: "https://www.bungie.net#{bg}",
            last_login: last_played
          )

          @details.save!
        else
          @character.character_details.update(
            character_type: type,
            subclass: subclass_name,
            light_level: light,
            emblem: "https://www.bungie.net#{emblem}",
            emblem_background: "https://www.bungie.net#{bg}",
            last_login: last_played
          )
        end
      end

      character_data[id] = {
        "character_type": type,
        "subclass": subclass_name,
        "light_level": light,
        "emblem": "https://www.bungie.net#{emblem}",
        "emblem_background": "https://www.bungie.net#{bg}",
        "last_login": last_played
      }

      user.character_data = character_data
      user.save!
    end
  end
end
