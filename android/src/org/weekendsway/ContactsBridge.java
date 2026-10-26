package org.weekendsway;

import android.content.ContentResolver;
import android.content.Context;
import android.database.Cursor;
import android.provider.ContactsContract;
import android.provider.ContactsContract.CommonDataKinds.Phone;
import android.provider.ContactsContract.CommonDataKinds.StructuredPostal;
import android.telephony.PhoneNumberUtils;

import org.json.JSONArray;
import org.json.JSONObject;

import java.util.LinkedHashMap;

public final class ContactsBridge {
    private ContactsBridge() {}

    private static final class Entry {
        String id;
        String lookupKey;
        String name;
        String address = "";
        final LinkedHashMap<String, String> phones = new LinkedHashMap<>();
    }

    private static String text(Cursor cursor, int column) {
        String value = cursor.getString(column);
        return value == null ? "" : value.trim();
    }

    private static Cursor query(ContentResolver resolver, android.net.Uri uri,
                                String[] columns, String sort) {
        Cursor cursor = resolver.query(uri, columns, null, null, sort);
        if (cursor == null)
            throw new IllegalStateException("Contacts provider unavailable");
        return cursor;
    }

    // Called by C++ on a worker thread. No contact data leaves the device.
    public static String readContacts(Context context) {
        try {
            ContentResolver resolver = context.getContentResolver();
            LinkedHashMap<String, Entry> entries = new LinkedHashMap<>();
            try (Cursor cursor = query(resolver, ContactsContract.Contacts.CONTENT_URI,
                    new String[] {ContactsContract.Contacts._ID,
                        ContactsContract.Contacts.LOOKUP_KEY,
                        ContactsContract.Contacts.DISPLAY_NAME_PRIMARY},
                    ContactsContract.Contacts.DISPLAY_NAME_PRIMARY + " COLLATE LOCALIZED ASC")) {
                while (cursor.moveToNext()) {
                    Entry entry = new Entry();
                    entry.id = text(cursor, 0);
                    entry.lookupKey = text(cursor, 1);
                    entry.name = text(cursor, 2);
                    entries.put(entry.id, entry);
                }
            }
            try (Cursor cursor = query(resolver, Phone.CONTENT_URI,
                    new String[] {Phone.CONTACT_ID, Phone.NUMBER},
                    Phone.IS_SUPER_PRIMARY + " DESC, " + Phone.IS_PRIMARY + " DESC, " + Phone._ID + " ASC")) {
                while (cursor.moveToNext()) {
                    Entry entry = entries.get(text(cursor, 0));
                    String number = text(cursor, 1);
                    if (entry != null && !number.isEmpty()) {
                        String normalized = PhoneNumberUtils.normalizeNumber(number);
                        entry.phones.putIfAbsent(normalized.isEmpty() ? number : normalized, number);
                    }
                }
            }
            try (Cursor cursor = query(resolver, StructuredPostal.CONTENT_URI,
                    new String[] {StructuredPostal.CONTACT_ID, StructuredPostal.FORMATTED_ADDRESS,
                        StructuredPostal.STREET, StructuredPostal.CITY, StructuredPostal.REGION,
                        StructuredPostal.POSTCODE, StructuredPostal.COUNTRY},
                    StructuredPostal.IS_SUPER_PRIMARY + " DESC, " + StructuredPostal.IS_PRIMARY
                        + " DESC, " + StructuredPostal._ID + " ASC")) {
                while (cursor.moveToNext()) {
                    Entry entry = entries.get(text(cursor, 0));
                    if (entry == null || !entry.address.isEmpty())
                        continue;
                    entry.address = text(cursor, 1);
                    if (entry.address.isEmpty()) {
                        StringBuilder address = new StringBuilder();
                        for (int column = 2; column < 7; ++column) {
                            String part = text(cursor, column);
                            if (part.isEmpty()) continue;
                            if (address.length() > 0) address.append(", ");
                            address.append(part);
                        }
                        entry.address = address.toString();
                    }
                }
            }
            JSONArray contacts = new JSONArray();
            for (Entry entry : entries.values()) {
                String phone = android.text.TextUtils.join(" / ", entry.phones.values());
                if (entry.name.isEmpty() && phone.isEmpty() && entry.address.isEmpty())
                    continue;
                JSONObject contact = new JSONObject();
                contact.put("contactId", entry.id);
                contact.put("contactKey", entry.lookupKey);
                contact.put("name", entry.name.isEmpty() ? (phone.isEmpty() ? "Без имени" : phone) : entry.name);
                contact.put("phone", phone);
                contact.put("address", entry.address);
                contacts.put(contact);
            }
            return new JSONObject().put("contacts", contacts).toString();
        } catch (SecurityException error) {
            return "{\"error\":\"permission\"}";
        } catch (Exception error) {
            // Do not log names, numbers or provider responses.
            return "{\"error\":\"read\"}";
        }
    }
}
