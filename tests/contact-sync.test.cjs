const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const vm = require('node:vm');
const { test } = require('node:test');

const source = fs.readFileSync(path.join(__dirname, '../qml/utils/ContactSync.js'), 'utf8')
  .replace(/^\.pragma library\s*/, '');
const sync = vm.createContext({});
vm.runInContext(source, sync);
const plain = value => JSON.parse(JSON.stringify(value));
const contact = (id, changes = {}) => ({ contactId: id, contactKey: 'lookup-' + id,
  name: 'Друг ' + id, phone: '', address: '', ...changes });
const merge = (friends, selected, all) => plain(sync.merge(friends, selected, all));

test('imports selected contacts, including records without a phone or address', () => {
  const all = [contact('1'), contact('2', { phone: '+7 999 111-22-33' }), contact('3')];
  const result = merge([], [all[1]], all);
  assert.equal(result.added, 1);
  assert.equal(result.friends.length, 1);
  assert.equal(result.friends[0].sourceContactId, '2');
  assert.equal(result.friends[0].phone, all[1].phone);
  assert.equal(merge([], all).friends.length, 3);
});

test('repeating all-contact sync does not add duplicates, even after a restart', () => {
  const all = [contact('1'), contact('2')];
  const first = merge([], all);
  const reloaded = plain(sync.normalizeFriends(first.friends));
  const second = merge(reloaded, all);
  assert.equal(second.added, 0);
  assert.equal(second.updated, 0);
  assert.equal(second.unchanged, 2);
  assert.deepEqual(second.friends, reloaded);
});

test('refreshes imported values, preserving every manually edited field', () => {
  const original = contact('1', { name: 'Аня', phone: '+7 999 111-22-33', address: 'Старый адрес' });
  const saved = merge([], [original]).friends;
  Object.assign(saved[0], { name: 'Анюта', address: 'Мой адрес', intercom: '42#', floor: '4', apartment: '20' });
  const changed = { ...original, name: 'Анна', phone: '+7 999 222-33-44', address: 'Новый адрес' };
  const result = merge(saved, [changed]);
  assert.equal(result.updated, 1);
  assert.equal(result.friends[0].name, 'Анюта');
  assert.equal(result.friends[0].address, 'Мой адрес');
  assert.equal(result.friends[0].phone, changed.phone);
  assert.equal(result.friends[0].intercom, '42#');
  assert.equal(result.friends[0].floor, '4');
  assert.equal(result.friends[0].apartment, '20');
  assert.equal(saved[0].phone, original.phone, 'merge must not mutate records before saving');
});

test('matches a manual friend by a normalized phone, preserving its address', () => {
  const saved = [{ name: 'Иван', phone: '8 (999) 111-22-33', address: 'Дом', intercom: '123' }];
  const result = merge(saved, [contact('1', { name: 'Ваня', phone: '+7 999 111 22 33' })]);
  assert.equal(result.added, 0);
  assert.equal(result.friends[0].name, 'Иван');
  assert.equal(result.friends[0].address, 'Дом');
  assert.equal(result.friends[0].sourceContactId, '1');
});

test('links an old record with a unique name, without creating a duplicate', () => {
  const result = merge([{ name: '  Анна Петрова ', address: 'Дом' }],
    [contact('1', { name: 'Анна Петрова', phone: '12345' })]);
  assert.equal(result.added, 0);
  assert.equal(result.friends[0].phone, '12345');
  assert.equal(result.friends[0].address, 'Дом');
});

test('does not guess between namesakes, including when only one is selected', () => {
  const all = [contact('1', { name: 'Саша' }), contact('2', { name: 'Саша' })];
  const result = merge([{ name: 'Саша', address: 'Дом' }], [all[0]], all);
  assert.equal(result.added, 1);
  assert.equal(result.friends[0].sourceContactId, '');
  assert.equal(merge([{ name: 'Саша' }, { name: 'Саша', address: 'Офис' }], [all[0]]).added, 1);
});

test('keeps different contacts with a shared family number separate', () => {
  const all = [contact('1', { phone: '12345' }), contact('2', { phone: '12345' })];
  const first = merge([], all);
  assert.equal(first.added, 2);
  assert.equal(merge(first.friends, all).friends.length, 2);
});

test('updates a changed lookup key by the same id and phone', () => {
  const original = contact('1', { phone: '12345' });
  const result = merge(merge([], [original]).friends, [{ ...original, contactKey: 'new-key' }]);
  assert.equal(result.added, 0);
  assert.equal(result.friends[0].sourceContactKey, 'new-key');
});

test('a missing or deleted phone contact never removes a friend', () => {
  const saved = merge([], [contact('1'), contact('2')]).friends;
  const result = merge(saved, [contact('1')]);
  assert.equal(result.friends.length, 2);
  assert.equal(merge(saved, []).friends.length, 2);
});

test('normalization preserves imported metadata and tolerates older records', () => {
  const original = merge([], [contact('1')]).friends[0];
  const result = plain(sync.normalizeFriends([null, {}, { name: 'Старый друг', floor: 3 }, original]));
  assert.equal(result.length, 2);
  assert.equal(result[0].floor, '3');
  assert.equal(result[0].sourceContactKey, '');
  assert.deepEqual(result[1], original);
});

test('a repeated item in the same import is added only once', () => {
  const item = contact('1');
  assert.equal(merge([], [item, item]).friends.length, 1);
});

test('handles a large address book without losing records', () => {
  const all = Array.from({ length: 5000 }, (_, id) => contact(String(id), { phone: '7999' + String(id).padStart(7, '0') }));
  const first = merge([], all);
  assert.equal(first.added, 5000);
  const second = merge(first.friends, all);
  assert.equal(second.added, 0);
  assert.equal(second.unchanged, 5000);
});
