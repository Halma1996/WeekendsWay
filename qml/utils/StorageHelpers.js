.pragma library

function modelToArray(model) {
    var arr = []
    for (var i = 0; i < model.count; ++i) {
        arr.push(model.get(i))
    }
    return arr
}

function arrayToModel(arr, model) {
    model.clear()
    if (!arr || arr.length === undefined) return
    for (var i = 0; i < arr.length; ++i) {
        if (arr[i]) model.append(arr[i])
    }
}

function normalizeNameAddressArray(arr) {
    var out = []
    if (!arr || arr.length === undefined) return out

    for (var i = 0; i < arr.length; ++i) {
        var it = arr[i]
        if (!it) continue

        var n = (it.name !== undefined) ? ("" + it.name).trim() : ""
        var a = (it.address !== undefined) ? ("" + it.address).trim() : ""

        if (n.length === 0 && a.length === 0) continue
        out.push({ name: n, address: a })
    }
    return out
}
