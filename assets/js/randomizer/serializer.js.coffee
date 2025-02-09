#= require randomizer/util.js.coffee
#= require models/kingdom.js.coffee
#= require models/supply.js.coffee

do ->
   Kingdom = window.Kingdom
   Supply = window.Supply
   Util = window.Util

   serializeKingdom = (kingdom) ->
      result = []
      result.push(serializeSupply(kingdom.getSupply().getCards()))
      result.push(serializeEvents(kingdom.getEvents())) if kingdom.getEvents().length
      result.push(serializeLandmarks(kingdom.getLandmarks())) if kingdom.getLandmarks().length
      result.push(serializeProjects(kingdom.getProjects())) if kingdom.getProjects().length

      serializedMetadata = serializeMetadata(kingdom.getMetadata())
      result.push(serializedMetadata) if serializedMetadata.length
      return result.join('&')

   deserializeKingdom = (allSets, serializedKingdom) -> 
      supplyIds = parseNamedCommaSeparatedParameter('supply', serializedKingdom)

      # The supply cards used to be serialized under the cards parameter, check if the old parameter
      # name is being used.
      if !supplyIds
         supplyIds = parseNamedCommaSeparatedParameter('cards', serializedKingdom) or []

      if !supplyIds.length
         return null

      eventIds = parseNamedCommaSeparatedParameter('events', serializedKingdom) or []
      landmarkIds = parseNamedCommaSeparatedParameter('landmarks', serializedKingdom) or []
      projectIds = parseNamedCommaSeparatedParameter('projects', serializedKingdom) or []
      useShelters = parseNamedBooleanParameter('shelters', serializedKingdom)
      useColonies = parseNamedBooleanParameter('colonies', serializedKingdom)

      allCards = Util.flattenSetsForProperty(allSets, 'cards')
      allEvents = Util.flattenSetsForProperty(allSets, 'events')
      allLandmarks = Util.flattenSetsForProperty(allSets, 'landmarks')
      allProjects = Util.flattenSetsForProperty(allSets, 'projects')

      cards = findByIds(supplyIds, allCards).slice(0, 10)
      events = findByIds(eventIds, allEvents).slice(0, 2)
      landmarks = findByIds(landmarkIds, allLandmarks).slice(0, Math.max(0, 2 - events.length))
      projects = findByIds(projectIds, allProjects).slice(0, Math.max(0, 2 - events.length - landmarks.length))

      supplyMetadata = new Supply.Metadata(null, null, null, null)
      supply = new Supply(cards, supplyMetadata)

      return new Kingdom(supply, events, landmarks, projects, deserializeMetadata(serializedKingdom))

   serializeSupply = (supplyCards) ->
      sortedSupplyCards = supplyCards.concat().sort (a, b) ->
         return 1 if a.shortId > b.shortId
         return -1 if a.shortId < b.shortId
         return 0

      return "supply=#{serializeCardsWithShortIds(sortedSupplyCards)}"

   serializeEvents = (events) ->
      return "events=#{serializeCardsWithShortIds(events)}"

   serializeLandmarks = (landmarks) ->
      return "landmarks=#{serializeCardsWithShortIds(landmarks)}"

   serializeProjects = (projects) ->
      return "projects=#{serializeCardsWithShortIds(projects)}"

   serializeCardsWithShortIds = (cards) ->
      return '' unless cards.length
      ids = (card.shortId for card in cards)
      return ids.join(',')

   serializeMetadata = (metadata) ->
      result = []
      if metadata.getUseColonies()
         result.push('colonies=1')
      if metadata.getUseShelters()
         result.push('shelters=1')
      return result.join('&')

   deserializeMetadata = (serializedKingdom) ->
      return new Kingdom.Metadata(
            parseNamedBooleanParameter('colonies', serializedKingdom)
            parseNamedBooleanParameter('shelters', serializedKingdom))

   findByIds = (cardIds, cards) ->
      foundCards = []
      for cardId in cardIds
         foundCard = findById(cardId, cards)
         foundCards.push(foundCard) if foundCard
      return foundCards

   findById = (cardId, cards) ->
      for card in cards
         if card.id == cardId || card.shortId == cardId
            return card
      return null

   parseNamedCommaSeparatedParameter = (parameter, serializedKingdom) ->
      value = parseNamedParameter(parameter, serializedKingdom)
      return null unless value
      return value.split(',')

   parseNamedBooleanParameter = (parameter, serializedKingdom) ->
      value = parseNamedParameter(parameter, serializedKingdom)
      return  value == '1' || value == 'true'

   parseNamedParameter = (parameter, serializedKingdom) ->
      regex = new RegExp("#{parameter}=([\\w,]+)")
      matches = regex.exec(serializedKingdom)
      return null unless matches?[1]
      return matches[1]


   window.Serializer = {
      serializeKingdom: serializeKingdom
      deserializeKingdom: deserializeKingdom
   }
