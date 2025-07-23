# מדריך מופעים מרובים של Cursor Web

מדריך זה מסביר איך להריץ מספר מופעים של Cursor Web על פורטים שונים.

## 🎯 אפשרויות זמינות

### 1. **cursor_manager.sh** - עם Docker (מומלץ לפרודקשן)
- ✅ **יתרונות:**
  - בידוד מלא בין מופעים
  - ניהול קל של משאבים
  - סגירה נקייה של מופעים
  - יציבות גבוהה
  - קל לניהול ולתחזוקה

- ❌ **חסרונות:**
  - דורש Docker
  - overhead קל של קונטיינרים
  - גישה מוגבלת למערכת (רק לספריות מוגדרות)

### 2. **cursor_multi_instance.sh** - ישירות על השרת
- ✅ **יתרונות:**
  - גישה מלאה למערכת
  - ביצועים טובים יותר
  - אין צורך ב-Docker
  - שליטה מלאה

- ❌ **חסרונות:**
  - ניהול מורכב יותר
  - סיכון לניגודי משאבים
  - קשה יותר לסגירה נקייה

## 🚀 התקנה ושימוש

### אפשרות 1: עם Docker

```bash
# הרץ הרשאות
chmod +x cursor_manager.sh

# צור מופע ראשון
sudo ./cursor_manager.sh create 8080

# צור מופע שני
sudo ./cursor_manager.sh create 8081 user2 pass2 /home/user2

# צור מופע שלישי
sudo ./cursor_manager.sh create 8082 user3 pass3 /home/user3

# רשימת מופעים
./cursor_manager.sh list

# עצירת מופע
sudo ./cursor_manager.sh stop 8080

# הפעלת מופע
sudo ./cursor_manager.sh start 8080

# מחיקת מופע
sudo ./cursor_manager.sh remove 8080
```

### אפשרות 2: ישירות על השרת

```bash
# הרץ הרשאות
chmod +x cursor_multi_instance.sh

# התקן דרישות
sudo ./cursor_multi_instance.sh install

# צור מופע ראשון
sudo ./cursor_multi_instance.sh create 8080

# צור מופע שני
sudo ./cursor_multi_instance.sh create 8081 user2 pass2 /home/user2

# צור מופע שלישי
sudo ./cursor_multi_instance.sh create 8082 user3 pass3 /home/user3

# רשימת מופעים
./cursor_multi_instance.sh list

# עצירת מופע
sudo ./cursor_multi_instance.sh stop 8080

# הפעלת מופע
sudo ./cursor_multi_instance.sh start 8080

# הצגת לוגים
sudo ./cursor_multi_instance.sh logs 8080

# מחיקת מופע
sudo ./cursor_multi_instance.sh remove 8080
```

## 📊 השוואת ביצועים

| קריטריון | Docker | ישירות על השרת |
|-----------|--------|-----------------|
| **ביצועים** | טובים | מעולים |
| **יציבות** | מעולה | טובה |
| **בידוד** | מלא | חלקי |
| **ניהול** | קל | מורכב |
| **גישה למערכת** | מוגבלת | מלאה |
| **שימוש במשאבים** | גבוה יותר | נמוך יותר |
| **אבטחה** | גבוהה | בינונית |

## 🎯 המלצות

### לפרודקשן / שרתים משותפים:
**השתמש ב-`cursor_manager.sh` (Docker)**
- בידוד טוב יותר
- ניהול קל יותר
- יציבות גבוהה

### לשרת פרטי / פיתוח:
**השתמש ב-`cursor_multi_instance.sh` (ישירות)**
- ביצועים טובים יותר
- גישה מלאה למערכת
- שליטה מלאה

## 🔧 ניהול מתקדם

### יצירת סקריפט אוטומטי

```bash
#!/bin/bash
# auto_create_instances.sh

# צור 5 מופעים אוטומטית
for i in {8080..8084}; do
    user="user$((i-8079))"
    pass="pass$((i-8079))"
    workspace="/home/$user"
    
    echo "Creating instance on port $i for user $user"
    sudo ./cursor_manager.sh create $i $user $pass $workspace
done
```

### ניטור מופעים

```bash
#!/bin/bash
# monitor_instances.sh

echo "=== Cursor Web Instances Status ==="
./cursor_manager.sh list

echo ""
echo "=== System Resources ==="
echo "CPU Usage:"
top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1

echo "Memory Usage:"
free -h | grep Mem | awk '{print $3 "/" $2}'

echo "Disk Usage:"
df -h / | tail -1 | awk '{print $5}'
```

## 🛠️ פתרון בעיות

### בעיה: פורט תפוס
```bash
# בדוק מה רץ על הפורט
sudo netstat -tlnp | grep :8080

# או מצא פורט פנוי אוטומטית
./cursor_manager.sh create  # ימצא פורט פנוי אוטומטית
```

### בעיה: מופע לא נפתח
```bash
# בדוק לוגים
sudo ./cursor_multi_instance.sh logs 8080

# או בדוק סטטוס
sudo systemctl status cursor-8080.service
```

### בעיה: Docker לא זמין
```bash
# התקן Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER
```

## 📈 דוגמאות שימוש

### 1. סביבת פיתוח צוותית
```bash
# צור מופע לכל מפתח
sudo ./cursor_manager.sh create 8080 alice alice123 /home/alice/projects
sudo ./cursor_manager.sh create 8081 bob bob123 /home/bob/projects
sudo ./cursor_manager.sh create 8082 charlie charlie123 /home/charlie/projects
```

### 2. סביבת בדיקות
```bash
# צור מופעים לבדיקות שונות
sudo ./cursor_multi_instance.sh create 8080 test1 test123 /test/env1
sudo ./cursor_multi_instance.sh create 8081 test2 test123 /test/env2
sudo ./cursor_multi_instance.sh create 8082 test3 test123 /test/env3
```

### 3. סביבת ייצור
```bash
# צור מופעים יציבים עם Docker
sudo ./cursor_manager.sh create 8080 prod1 prod123 /var/www/prod1
sudo ./cursor_manager.sh create 8081 prod2 prod123 /var/www/prod2
```

## 🔒 אבטחה

### עם Docker:
- בידוד מלא בין מופעים
- הרשאות מוגבלות
- קל לניהול אבטחה

### ישירות על השרת:
- השתמש בסיסמאות חזקות
- הגבל גישה לפי IP
- השתמש ב-firewall
- עקוב אחר לוגים

## 📞 תמיכה

לשאלות נוספות או בעיות:
1. בדוק את הלוגים: `sudo journalctl -u cursor-8080.service`
2. בדוק את הסטטוס: `sudo systemctl status cursor-8080.service`
3. בדוק את הפורטים: `sudo netstat -tlnp | grep :8080`