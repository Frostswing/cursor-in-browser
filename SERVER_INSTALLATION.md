# התקנת Cursor Web ישירות על השרת

מדריך זה מסביר איך להריץ את Cursor Web ישירות על השרת (לא בתוך קונטיינר) כדי לקבל גישה מלאה למערכת.

## אפשרויות התקנה

### אפשרות 1: התקנה מלאה עם systemd (מומלץ)

```bash
# הרץ את הסקריפט עם הרשאות sudo
sudo chmod +x install_cursor_web.sh
sudo ./install_cursor_web.sh
```

זה ייצור שירות systemd שירוץ אוטומטית בעת הפעלת השרת.

### אפשרות 2: הרצה ידנית

```bash
# הרץ את הסקריפט הפשוט
chmod +x run_cursor_web.sh
./run_cursor_web.sh
```

## גישה ל-Cursor Web

לאחר ההתקנה, Cursor Web יהיה זמין בכתובת:
```
http://YOUR_SERVER_IP:8080
```

## ניהול השירות

### אם התקנת עם systemd:

```bash
# בדיקת סטטוס
sudo systemctl status cursor-web.service

# הפעלה
sudo systemctl start cursor-web.service

# עצירה
sudo systemctl stop cursor-web.service

# הפעלה מחדש
sudo systemctl restart cursor-web.service

# הפעלה אוטומטית בעת הפעלת השרת
sudo systemctl enable cursor-web.service
```

### אם הרצת ידנית:

השתמש ב-`Ctrl+C` כדי לעצור את הסקריפט.

## מיקומי קבצים

- **Cursor AppImage**: `/opt/cursor-web/Cursor.AppImage`
- **ספריית עבודה**: `/opt/cursor-web/cursor`
- **קבצי הגדרות**: `/opt/cursor-web/config`
- **סקריפט הפעלה**: `/opt/cursor-web/start_cursor.sh`

## פתרון בעיות

### בעיה: פורט 8080 תפוס
```bash
# בדוק מה רץ על הפורט
sudo netstat -tlnp | grep :8080

# או שנה את הפורט בסקריפט
```

### בעיה: אין הרשאות
```bash
# וודא שיש לך הרשאות sudo
sudo whoami
```

### בעיה: Cursor לא נפתח
```bash
# בדוק לוגים
sudo journalctl -u cursor-web.service -f

# או הרץ ידנית לבדיקת שגיאות
./run_cursor_web.sh
```

## יתרונות הרצה ישירה על השרת

1. **גישה מלאה למערכת** - לא מוגבל לקונטיינר
2. **ביצועים טובים יותר** - אין overhead של קונטיינר
3. **גישה לכל הקבצים** - לא רק לספריות מוגדרות
4. **שליטה מלאה** - אפשרות להתקין חבילות נוספות
5. **ניהול קל יותר** - שירות systemd סטנדרטי

## דרישות מערכת

- Ubuntu/Debian (מומלץ)
- לפחות 2GB RAM
- לפחות 1GB מקום פנוי
- חיבור אינטרנט להורדת Cursor