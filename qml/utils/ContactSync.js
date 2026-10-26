.pragma library

function value(item, field) {
    return String(item[field] == null ? "" : item[field]).trim()
}

function normalizeFriends(items) {
    var out = []
    if (!items || items.length === undefined) return out
    var fields = ["name", "address", "phone", "intercom", "floor", "apartment",
                  "sourceContactId", "sourceContactKey", "syncedName", "syncedPhone", "syncedAddress"]
    for (var i = 0; i < items.length; ++i) {
        if (!items[i]) continue
        var friend = {}
        for (var f = 0; f < fields.length; ++f)
            friend[fields[f]] = value(items[i], fields[f])
        if (friend.name || friend.address || friend.phone) out.push(friend)
    }
    return out
}

function phoneKeys(phone) {
    var parts = String(phone || "").split(/\s*\/\s*|\n|;/)
    var keys = []
    for (var i = 0; i < parts.length; ++i) {
        var key = parts[i].replace(/\D/g, "")
        if (/^8\d{10}$/.test(key)) key = "7" + key.slice(1)
        if (key && keys.indexOf(key) < 0) keys.push(key)
    }
    return keys
}

function nameKey(name) {
    return String(name || "").trim().toLocaleLowerCase().replace(/\s+/g, " ")
}

function addIndex(map, key, index) {
    if (!key) return
    if (!map[key]) map[key] = []
    if (map[key].indexOf(index) < 0) map[key].push(index)
}

function uniqueIndex(indices) {
    return indices && indices.length === 1 ? indices[0] : -1
}

// Returns new records. The caller persists them before replacing the visible model.
// Only fields that still equal their last imported value may be refreshed.
function merge(existing, selected, allContacts) {
    var friends = normalizeFriends(existing)
    var byKey = Object.create(null)
    var byId = Object.create(null)
    var byPhone = Object.create(null)
    var byName = Object.create(null)
    var contactNames = Object.create(null)
    var seen = Object.create(null)
    var added = 0, updated = 0, unchanged = 0
    var contacts = allContacts || selected
    for (var c = 0; c < contacts.length; ++c) {
        var nk = nameKey(contacts[c].name)
        contactNames[nk] = (contactNames[nk] || 0) + 1
    }

    function indexFriend(friend, index) {
        addIndex(byKey, friend.sourceContactKey, index)
        addIndex(byId, friend.sourceContactId, index)
        addIndex(byName, nameKey(friend.name), index)
        var phones = phoneKeys(friend.phone).concat(phoneKeys(friend.syncedPhone))
        for (var p = 0; p < phones.length; ++p) addIndex(byPhone, phones[p], index)
    }
    for (var f = 0; f < friends.length; ++f) indexFriend(friends[f], f)

    for (var s = 0; s < selected.length; ++s) {
        var contact = selected[s]
        var id = value(contact, "contactId"), key = value(contact, "contactKey")
        if (!id && !key) continue
        var identity = key ? "key:" + key : "id:" + id
        if (seen[identity]) continue
        seen[identity] = true
        var match = uniqueIndex(byKey[key])
        if (match < 0) {
            var byIdMatch = uniqueIndex(byId[id])
            if (byIdMatch >= 0 && (!key || !friends[byIdMatch].sourceContactKey)) match = byIdMatch
        }
        if (match < 0) {
            var candidates = []
            var numbers = phoneKeys(contact.phone)
            for (var n = 0; n < numbers.length; ++n) {
                var matches = byPhone[numbers[n]] || []
                for (var m = 0; m < matches.length; ++m) {
                    var candidate = friends[matches[m]]
                    // Distinct phone contacts can share a family or office number.
                    if ((!candidate.sourceContactId && !candidate.sourceContactKey)
                            || candidate.sourceContactId === id) {
                        if (candidates.indexOf(matches[m]) < 0) candidates.push(matches[m])
                    }
                }
            }
            match = uniqueIndex(candidates)
        }
        if (match < 0 && contactNames[nameKey(contact.name)] === 1) {
            var named = byName[nameKey(contact.name)] || []
            var nameMatch = uniqueIndex(named)
            if (nameMatch >= 0 && !friends[nameMatch].phone
                    && !friends[nameMatch].sourceContactId && !friends[nameMatch].sourceContactKey)
                match = nameMatch
        }

        var isNew = match < 0
        var item = isNew ? normalizeFriends([{ name: value(contact, "name") || "Без имени" }])[0]
                         : friends[match]
        var before = JSON.stringify(item)
        var fields = ["name", "phone", "address"]
        var snapshots = ["syncedName", "syncedPhone", "syncedAddress"]
        for (var j = 0; j < fields.length; ++j) {
            var field = fields[j], snapshot = snapshots[j]
            if (isNew || !item[field] || (item[snapshot] && item[field] === item[snapshot]))
                item[field] = value(contact, field)
            item[snapshot] = value(contact, field)
        }
        item.sourceContactId = id
        item.sourceContactKey = key
        if (isNew) {
            friends.push(item)
            match = friends.length - 1
            ++added
        } else if (before !== JSON.stringify(item)) {
            ++updated
        } else {
            ++unchanged
        }
        indexFriend(item, match)
    }
    return { friends: friends, added: added, updated: updated, unchanged: unchanged }
}
