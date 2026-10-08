"""Editable translations. Columns: English, zh-Hans, zh-Hant, ja, ko, fr, de, es, pt, ar."""
from pathlib import Path
import json
ROOT=Path(__file__).resolve().parents[1]
LANGS=['en','zh-Hans','zh-Hant','ja','ko','fr','de','es','pt','ar']
ROWS='''World|世界|世界|世界|세계|Monde|Welt|Mundo|Mundo|العالم
Maps|地图|地圖|地図|지도|Cartes|Karten|Mapas|Mapas|الخرائط
Countries and territories|国家和地区|國家和地區|国と地域|국가 및 지역|Pays et territoires|Länder und Gebiete|Países y territorios|Países e territórios|البلدان والأقاليم
Regions|省州地区|省州地區|地方・州|지역|Régions|Regionen|Regiones|Regiões|المناطق
Search places|搜索地区|搜尋地區|場所を検索|장소 검색|Rechercher un lieu|Orte suchen|Buscar lugares|Buscar lugares|البحث عن أماكن
Settings|设置|設定|設定|설정|Réglages|Einstellungen|Ajustes|Ajustes|الإعدادات
Language|语言|語言|言語|언어|Langue|Sprache|Idioma|Idioma|اللغة
System language|跟随系统|跟隨系統|システム言語|시스템 언어|Langue du système|Systemsprache|Idioma del sistema|Idioma do sistema|لغة النظام
Done|完成|完成|完了|완료|Terminé|Fertig|Listo|Concluído|تم
Cancel|取消|取消|キャンセル|취소|Annuler|Abbrechen|Cancelar|Cancelar|إلغاء
OK|好|好|OK|확인|OK|OK|Aceptar|OK|حسنًا
Retry|重试|重試|再試行|다시 시도|Réessayer|Erneut versuchen|Reintentar|Tentar novamente|إعادة المحاولة
Notice|提示|提示|お知らせ|알림|Information|Hinweis|Aviso|Aviso|تنبيه
Color|颜色|顏色|色|색상|Couleur|Farbe|Color|Cor|اللون
Blue|蓝色|藍色|青|파랑|Bleu|Blau|Azul|Azul|أزرق
Pink|粉色|粉色|ピンク|분홍|Rose|Rosa|Rosa|Rosa|وردي
Green|绿色|綠色|緑|초록|Vert|Grün|Verde|Verde|أخضر
Yellow|黄色|黃色|黄|노랑|Jaune|Gelb|Amarillo|Amarelo|أصفر
Monochrome|黑白|黑白|モノクロ|흑백|Monochrome|Schwarzweiß|Monocromo|Monocromático|أبيض وأسود
Photos|照片|照片|写真|사진|Photos|Fotos|Fotos|Fotos|الصور
Notes|留言|筆記|メモ|메모|Notes|Notizen|Notas|Notas|الملاحظات
About|关于|關於|情報|정보|À propos|Über|Acerca de|Sobre|حول
Photo access|照片权限|照片權限|写真へのアクセス|사진 접근|Accès aux photos|Fotozugriff|Acceso a fotos|Acesso às fotos|الوصول إلى الصور
Not requested|尚未申请|尚未申請|未リクエスト|요청하지 않음|Non demandé|Nicht angefordert|Sin solicitar|Não solicitado|لم يُطلب بعد
Full access|全部照片|全部照片|フルアクセス|전체 접근|Accès complet|Vollzugriff|Acceso completo|Acesso completo|وصول كامل
Selected photos only|仅所选照片|僅所選照片|選択した写真のみ|선택한 사진만|Photos sélectionnées|Ausgewählte Fotos|Solo fotos elegidas|Apenas fotos escolhidas|الصور المحددة فقط
Access denied|未允许访问|未允許存取|アクセス拒否|접근 거부|Accès refusé|Zugriff verweigert|Acceso denegado|Acesso negado|رُفض الوصول
Restricted by the system|受系统限制|受系統限制|システムによる制限|시스템 제한|Restriction du système|Vom System eingeschränkt|Restricción del sistema|Restrição do sistema|مقيّد من النظام
Allow photo library access|允许读取图库|允許讀取圖庫|写真ライブラリへのアクセスを許可|사진 보관함 접근 허용|Autoriser la photothèque|Fotomediathek freigeben|Permitir acceso a la fototeca|Permitir acesso à fototeca|السماح بالوصول إلى مكتبة الصور
Waiting for permission…|等待系统授权…|等待系統授權…|許可を待っています…|권한 대기 중…|En attente d’autorisation…|Warte auf Erlaubnis…|Esperando permiso…|Aguardando permissão…|بانتظار الإذن…
Open system settings|打开系统设置|開啟系統設定|システム設定を開く|시스템 설정 열기|Ouvrir les réglages système|Systemeinstellungen öffnen|Abrir ajustes del sistema|Abrir ajustes do sistema|فتح إعدادات النظام
Manage selected photos|管理所选照片|管理所選照片|選択した写真を管理|선택한 사진 관리|Gérer les photos choisies|Ausgewählte Fotos verwalten|Gestionar fotos elegidas|Gerir fotos escolhidas|إدارة الصور المحددة
Choose photos to classify|选择照片并自动归类|選擇照片並自動歸類|写真を選んで自動分類|사진 선택 및 자동 분류|Choisir des photos à classer|Fotos zum Zuordnen wählen|Elegir fotos para clasificar|Escolher fotos para classificar|اختيار صور لتصنيفها
Importing…|正在导入…|正在匯入…|読み込み中…|가져오는 중…|Importation…|Importieren…|Importando…|Importando…|جارٍ الاستيراد…
Scan on opening|打开时自动整理|開啟時自動整理|起動時にスキャン|실행 시 자동 정리|Analyser à l’ouverture|Beim Öffnen scannen|Analizar al abrir|Analisar ao abrir|الفحص عند الفتح
Scan photos|整理照片|整理照片|写真をスキャン|사진 정리|Analyser les photos|Fotos scannen|Analizar fotos|Analisar fotos|فحص الصور
Scanning…|正在整理…|正在整理…|スキャン中…|정리 중…|Analyse…|Scannen…|Analizando…|Analisando…|جارٍ الفحص…
Rescan all photos|重新扫描全部照片|重新掃描全部照片|すべて再スキャン|모든 사진 다시 정리|Tout réanalyser|Alle erneut scannen|Volver a analizar todo|Analisar tudo novamente|إعادة فحص كل الصور
Last scan: {0}|上次整理：{0}|上次整理：{0}|前回：{0}|최근 정리: {0}|Dernière analyse : {0}|Letzter Scan: {0}|Último análisis: {0}|Última análise: {0}|آخر فحص: {0}
Unsorted photos|待归类照片|待歸類照片|未分類の写真|미분류 사진|Photos non classées|Nicht zugeordnete Fotos|Fotos sin clasificar|Fotos não classificadas|صور غير مصنفة
Visited places|已去过的地方|已去過的地方|訪れた場所|방문한 장소|Lieux visités|Besuchte Orte|Lugares visitados|Lugares visitados|الأماكن التي زرتها
Visited|已去过|已去過|訪問済み|방문함|Visité|Besucht|Visitado|Visitado|تمت الزيارة
Mark as visited|标记为去过|標記為去過|訪問済みにする|방문 표시|Marquer comme visité|Als besucht markieren|Marcar como visitado|Marcar como visitado|تحديد كمكان تمت زيارته
Remove manual mark|取消手动标记|取消手動標記|手動マークを解除|수동 표시 해제|Retirer la marque manuelle|Manuelle Markierung entfernen|Quitar marca manual|Remover marca manual|إزالة العلامة اليدوية
Keep a manual mark|保留手动标记|保留手動標記|手動マークを追加|수동 표시 유지|Garder une marque manuelle|Manuelle Markierung behalten|Conservar marca manual|Manter marca manual|الاحتفاظ بعلامة يدوية
Photos keep this place marked.|照片会让此处保持点亮。|照片會讓此處保持點亮。|写真がある場所はマークされます。|사진이 있는 장소는 표시됩니다.|Les photos gardent ce lieu marqué.|Fotos halten diesen Ort markiert.|Las fotos mantienen este lugar marcado.|As fotos mantêm este lugar marcado.|تُبقي الصور هذا المكان معلّمًا.
No photos yet|这里还没有照片|這裡還沒有照片|写真はまだありません|아직 사진이 없습니다|Aucune photo|Noch keine Fotos|Aún no hay fotos|Ainda não há fotos|لا توجد صور بعد
Tap + to add photos.|点加号添加照片。|點加號加入照片。|＋で写真を追加。|+를 눌러 사진을 추가하세요.|Touchez + pour ajouter des photos.|Mit + Fotos hinzufügen.|Toca + para añadir fotos.|Toque em + para adicionar fotos.|اضغط + لإضافة صور.
Add photos|添加照片|加入照片|写真を追加|사진 추가|Ajouter des photos|Fotos hinzufügen|Añadir fotos|Adicionar fotos|إضافة صور
Newest first|最新优先|最新優先|新しい順|최신순|Plus récentes|Neueste zuerst|Más recientes|Mais recentes|الأحدث أولًا
Oldest first|最早优先|最早優先|古い順|오래된순|Plus anciennes|Älteste zuerst|Más antiguas|Mais antigas|الأقدم أولًا
Manual order|手动排序|手動排序|手動順|수동 정렬|Ordre manuel|Manuelle Reihenfolge|Orden manual|Ordem manual|ترتيب يدوي
Move to start|移到最前|移到最前|先頭に移動|맨 앞으로|Placer au début|An den Anfang|Mover al inicio|Mover para o início|نقل إلى البداية
Move to end|移到最后|移到最後|末尾に移動|맨 뒤로|Placer à la fin|Ans Ende|Mover al final|Mover para o fim|نقل إلى النهاية
Remove from Footprints|从足迹中移除|從足跡中移除|Footprintsから削除|Footprints에서 제거|Retirer de Footprints|Aus Footprints entfernen|Quitar de Footprints|Remover de Footprints|إزالة من Footprints
Close photo|关闭照片|關閉照片|写真を閉じる|사진 닫기|Fermer la photo|Foto schließen|Cerrar foto|Fechar foto|إغلاق الصورة
Photo actions|照片操作|照片操作|写真の操作|사진 작업|Actions photo|Fotoaktionen|Acciones de foto|Ações da foto|إجراءات الصورة
Reassign|重新归类|重新歸類|再分類|다시 분류|Reclasser|Neu zuordnen|Reclasificar|Reclassificar|إعادة التصنيف
View date|查看日期|查看日期|日付を表示|날짜 보기|Voir la date|Datum anzeigen|Ver fecha|Ver data|عرض التاريخ
Date taken|拍摄时间|拍攝時間|撮影日時|촬영 날짜|Date de prise de vue|Aufnahmedatum|Fecha de captura|Data da captura|تاريخ الالتقاط
No date recorded.|没有记录拍摄日期。|沒有記錄拍攝日期。|撮影日はありません。|날짜 정보가 없습니다.|Aucune date enregistrée.|Kein Datum gespeichert.|No hay fecha registrada.|Sem data registada.|لا يوجد تاريخ مسجّل.
Write a memory…|写下关于这里的记忆…|寫下關於這裡的記憶…|思い出を書きましょう…|추억을 적어보세요…|Écrivez un souvenir…|Eine Erinnerung schreiben…|Escribe un recuerdo…|Escreva uma memória…|اكتب ذكرى…
Place notes|地区留言|地區筆記|場所のメモ|장소 메모|Notes du lieu|Ortsnotizen|Notas del lugar|Notas do lugar|ملاحظات المكان
No unsorted photos|暂无待归类照片|暫無待歸類照片|未分類の写真はありません|미분류 사진 없음|Aucune photo à classer|Keine unzugeordneten Fotos|No hay fotos sin clasificar|Sem fotos por classificar|لا توجد صور غير مصنفة
Photos without a matched location appear here.|没有位置或未匹配地区的照片会在这里。|沒有位置或未匹配地區的照片會在這裡。|場所が一致しない写真がここに表示されます。|위치가 일치하지 않는 사진이 표시됩니다.|Les photos sans lieu reconnu apparaissent ici.|Fotos ohne passenden Ort erscheinen hier.|Aquí aparecen fotos sin lugar reconocido.|As fotos sem local reconhecido aparecem aqui.|تظهر هنا الصور التي لا تطابق موقعًا.
Select all|全选|全選|すべて選択|모두 선택|Tout sélectionner|Alle auswählen|Seleccionar todo|Selecionar tudo|تحديد الكل
Deselect all|取消全选|取消全選|すべて解除|모두 해제|Tout désélectionner|Alle abwählen|Deseleccionar todo|Desmarcar tudo|إلغاء تحديد الكل
Select photo|选择照片|選擇照片|写真を選択|사진 선택|Choisir la photo|Foto auswählen|Seleccionar foto|Selecionar foto|تحديد الصورة
Deselect photo|取消选择照片|取消選擇照片|写真の選択を解除|사진 선택 해제|Désélectionner la photo|Foto abwählen|Deseleccionar foto|Desmarcar foto|إلغاء تحديد الصورة
Assign {0} photos…|将 {0} 张照片归类到…|將 {0} 張照片歸類到…|{0}枚の写真を分類…|사진 {0}장 분류…|Classer {0} photos…|{0} Fotos zuordnen…|Clasificar {0} fotos…|Classificar {0} fotos…|تصنيف {0} صورة…
Assign to…|归类到…|歸類到…|分類先…|분류할 장소…|Classer dans…|Zuordnen zu…|Clasificar en…|Classificar em…|التصنيف ضمن…
Explore regions|查看省州地图|查看省州地圖|地方を探索|지역 탐색|Explorer les régions|Regionen erkunden|Explorar regiones|Explorar regiões|استكشاف المناطق
No subdivisions in this dataset.|此数据集没有细分地区。|此資料集沒有細分地區。|このデータには地方区分がありません。|이 데이터에는 세부 지역이 없습니다.|Pas de subdivisions dans ces données.|Keine Unterteilungen in diesen Daten.|Sin subdivisiones en estos datos.|Sem subdivisões nestes dados.|لا توجد تقسيمات في هذه البيانات.
Map unavailable|地图无法加载|地圖無法載入|地図を読み込めません|지도를 불러올 수 없음|Carte indisponible|Karte nicht verfügbar|Mapa no disponible|Mapa indisponível|الخريطة غير متاحة
Travel map. Use the place list to select a region.|旅行地图，可通过地区列表选择。|旅行地圖，可透過地區列表選擇。|旅行地図。一覧から場所を選べます。|여행 지도. 목록에서 지역을 선택하세요.|Carte de voyage. Choisissez un lieu dans la liste.|Reisekarte. Orte über die Liste wählen.|Mapa de viajes. Elige un lugar de la lista.|Mapa de viagens. Escolha um local na lista.|خريطة السفر. اختر منطقة من القائمة.
Your world, one memory at a time.|用记忆，点亮世界。|用記憶，點亮世界。|思い出で、世界を彩ろう。|추억으로 세계를 채워보세요.|Votre monde, souvenir après souvenir.|Deine Welt, Erinnerung für Erinnerung.|Tu mundo, recuerdo a recuerdo.|O seu mundo, memória a memória.|عالمك، ذكرى تلو الأخرى.
Choose a map, mark places, and keep notes. Photos are optional.|选择地图、点亮足迹、写下留言。照片权限可稍后开启。|選擇地圖、點亮足跡、寫下筆記。照片權限可稍後開啟。|地図を選び、場所をマークしてメモを残しましょう。写真は任意です。|지도를 고르고 장소와 메모를 남기세요. 사진은 선택 사항입니다.|Choisissez une carte, marquez des lieux et prenez des notes. Les photos sont facultatives.|Karte wählen, Orte markieren, Notizen speichern. Fotos sind optional.|Elige un mapa, marca lugares y guarda notas. Las fotos son opcionales.|Escolha um mapa, marque locais e guarde notas. As fotos são opcionais.|اختر خريطة وحدّد الأماكن واكتب ملاحظات. الصور اختيارية.
Explore the map|进入地图|進入地圖|地図を開く|지도 열기|Explorer la carte|Karte öffnen|Explorar el mapa|Explorar o mapa|استكشاف الخريطة
Opening…|正在打开…|正在開啟…|開いています…|여는 중…|Ouverture…|Öffnen…|Abriendo…|A abrir…|جارٍ الفتح…
Offline and private|离线且私密|離線且私密|オフラインでプライベート|오프라인 및 비공개|Hors ligne et privé|Offline und privat|Sin conexión y privado|Offline e privado|دون اتصال وبخصوصية
No accounts, ads, analytics, or photo uploads.|无账号、广告、统计服务或照片上传。|無帳號、廣告、統計服務或照片上傳。|アカウント、広告、解析、写真のアップロードなし。|계정, 광고, 분석, 사진 업로드가 없습니다.|Sans compte, publicité, suivi ni envoi de photos.|Keine Konten, Werbung, Analyse oder Foto-Uploads.|Sin cuentas, anuncios, análisis ni subida de fotos.|Sem contas, anúncios, análises ou envio de fotos.|بلا حسابات أو إعلانات أو تحليلات أو رفع صور.
Uninstalling deletes local notes and imported copies.|卸载会删除本地留言和导入的副本。|解除安裝會刪除本機筆記和匯入的副本。|アンインストールするとメモと読み込んだコピーは削除されます。|앱 삭제 시 메모와 가져온 사본이 삭제됩니다.|La désinstallation supprime les notes et copies locales.|Deinstallation löscht lokale Notizen und importierte Kopien.|Desinstalar elimina notas y copias locales.|Desinstalar apaga notas e cópias locais.|إلغاء التثبيت يحذف الملاحظات والنسخ المحلية.
Map data and licenses|地图数据与许可|地圖資料與授權|地図データとライセンス|지도 데이터 및 라이선스|Données et licences|Kartendaten und Lizenzen|Datos y licencias|Dados e licenças|بيانات الخرائط والتراخيص
About Footprints|关于 Footprints|關於 Footprints|Footprintsについて|Footprints 정보|À propos de Footprints|Über Footprints|Acerca de Footprints|Sobre Footprints|حول Footprints
Delete local records|清除本地记录|清除本機記錄|ローカル記録を削除|로컬 기록 삭제|Effacer les données locales|Lokale Einträge löschen|Borrar registros locales|Apagar registos locais|حذف السجلات المحلية
Reset Footprints?|重置 Footprints？|重設 Footprints？|Footprintsをリセット？|Footprints 초기화?|Réinitialiser Footprints ?|Footprints zurücksetzen?|¿Restablecer Footprints?|Repor Footprints?|إعادة تعيين Footprints؟
Notes, marks and imported copies will be deleted. System photos stay untouched.|将删除留言、标记和导入副本，不会删除系统相册原图。|將刪除筆記、標記和匯入副本，不會刪除系統相簿原圖。|メモ、マーク、コピーを削除します。システムの写真は残ります。|메모, 표시 및 사본이 삭제됩니다. 원본 사진은 유지됩니다.|Notes, marques et copies seront supprimées. Les photos système restent intactes.|Notizen, Markierungen und Kopien werden gelöscht. Systemfotos bleiben erhalten.|Se borrarán notas, marcas y copias. Las fotos del sistema se conservan.|Notas, marcas e cópias serão apagadas. As fotos do sistema serão mantidas.|ستُحذف الملاحظات والعلامات والنسخ. صور النظام لن تتغير.
Could not save. Please retry.|未能保存，请重试。|未能儲存，請重試。|保存できません。再試行してください。|저장하지 못했습니다. 다시 시도하세요.|Enregistrement impossible. Réessayez.|Speichern fehlgeschlagen. Bitte erneut versuchen.|No se pudo guardar. Reintenta.|Não foi possível guardar. Tente novamente.|تعذّر الحفظ. أعد المحاولة.
Could not open local records.|无法打开本地记录。|無法開啟本機記錄。|ローカル記録を開けません。|로컬 기록을 열 수 없습니다.|Impossible d’ouvrir les données locales.|Lokale Einträge können nicht geöffnet werden.|No se pudieron abrir los registros locales.|Não foi possível abrir os registos locais.|تعذّر فتح السجلات المحلية.
Photo processing failed. Please retry.|照片处理失败，请重试。|照片處理失敗，請重試。|写真の処理に失敗しました。|사진 처리에 실패했습니다.|Le traitement a échoué. Réessayez.|Fotoverarbeitung fehlgeschlagen.|Falló el procesamiento. Reintenta.|Falha ao processar fotos. Tente novamente.|فشلت معالجة الصور. أعد المحاولة.
Scanned: {0}. With GPS: {1}. Grouped: {2}. Unsorted: {3}.|扫描：{0}。有定位：{1}。已归类：{2}。待归类：{3}。|掃描：{0}。有定位：{1}。已歸類：{2}。待歸類：{3}。|スキャン：{0}。GPSあり：{1}。分類済み：{2}。未分類：{3}。|스캔: {0}. GPS: {1}. 분류됨: {2}. 미분류: {3}.|Analysées : {0}. GPS : {1}. Classées : {2}. À classer : {3}.|Gescannt: {0}. Mit GPS: {1}. Zugeordnet: {2}. Offen: {3}.|Analizadas: {0}. GPS: {1}. Clasificadas: {2}. Sin clasificar: {3}.|Analisadas: {0}. GPS: {1}. Classificadas: {2}. Por classificar: {3}.|فُحصت: {0}. مع GPS: {1}. مصنفة: {2}. غير مصنفة: {3}.
Saved: {0}/{1}. Grouped: {2}. Unsorted: {3}. Failed: {4}.|已保存：{0}/{1}。已归类：{2}。待归类：{3}。失败：{4}。|已儲存：{0}/{1}。已歸類：{2}。待歸類：{3}。失敗：{4}。|保存：{0}/{1}。分類済み：{2}。未分類：{3}。失敗：{4}。|저장: {0}/{1}. 분류됨: {2}. 미분류: {3}. 실패: {4}.|Enregistrées : {0}/{1}. Classées : {2}. À classer : {3}. Échecs : {4}.|Gespeichert: {0}/{1}. Zugeordnet: {2}. Offen: {3}. Fehler: {4}.|Guardadas: {0}/{1}. Clasificadas: {2}. Sin clasificar: {3}. Fallidas: {4}.|Guardadas: {0}/{1}. Classificadas: {2}. Por classificar: {3}. Falhas: {4}.|حُفظت: {0}/{1}. مصنفة: {2}. غير مصنفة: {3}. فشلت: {4}.
Permission request did not finish. You can still choose photos to import.|授权请求未完成，仍可选择照片导入。|授權請求未完成，仍可選擇照片匯入。|許可リクエストが完了しませんでした。写真の選択は利用できます。|권한 요청이 완료되지 않았습니다. 사진 선택은 가능합니다.|La demande n’a pas abouti. Vous pouvez choisir des photos à importer.|Berechtigungsanfrage nicht abgeschlossen. Fotos können weiterhin ausgewählt werden.|La solicitud no terminó. Puedes elegir fotos para importar.|O pedido não terminou. Pode escolher fotos para importar.|لم يكتمل طلب الإذن. ما زال بإمكانك اختيار صور للاستيراد.
Choose up to 200 photos. GPS stays on this device; iCloud originals may need a download.|每批最多选 200 张。GPS 仅在本机处理；iCloud 原图可能需要下载。|每批最多選 200 張。GPS 僅在本機處理；iCloud 原圖可能需要下載。|最大200枚を選択。GPSは端末内で処理。iCloud原本はダウンロードが必要な場合があります。|최대 200장을 선택하세요. GPS는 기기에서 처리하며 iCloud 원본은 다운로드가 필요할 수 있습니다.|Jusqu’à 200 photos. GPS traité sur l’appareil ; les originaux iCloud peuvent nécessiter un téléchargement.|Bis zu 200 Fotos. GPS bleibt lokal; iCloud-Originale müssen eventuell geladen werden.|Hasta 200 fotos. GPS local; los originales de iCloud pueden necesitar descarga.|Até 200 fotos. GPS local; os originais do iCloud podem precisar de transferência.|اختر حتى 200 صورة. تُعالج بيانات GPS محليًا؛ قد تحتاج أصول iCloud إلى تنزيل.
Automatic scanning needs photo access. Private Access only shares photos you choose.|自动扫描需要图库授权。私密访问只能读取你主动选出的照片。|自動掃描需要圖庫授權。私密存取只能讀取你主動選出的照片。|自動スキャンには写真の許可が必要です。プライベートアクセスでは選択した写真のみ共有されます。|자동 스캔에는 사진 권한이 필요합니다. 비공개 접근은 선택한 사진만 공유합니다.|L’analyse automatique nécessite un accès. L’accès privé ne partage que vos sélections.|Automatisches Scannen benötigt Fotozugriff. Privater Zugriff teilt nur ausgewählte Fotos.|El análisis automático requiere permiso. El acceso privado solo comparte fotos elegidas.|A análise automática exige permissão. O acesso privado só partilha fotos escolhidas.|الفحص التلقائي يتطلب إذن الصور. الوصول الخاص يشارك الصور التي تختارها فقط.
Borders are approximate. Missing GPS cannot be recovered; assign a place manually.|边界为概化数据。缺失的 GPS 无法恢复，可手动指定地区。|邊界為概化資料。缺失的 GPS 無法恢復，可手動指定地區。|境界は概略です。欠落したGPSは復元できません。手動で場所を指定できます。|경계는 근사치입니다. 없는 GPS는 복원할 수 없으며 장소를 직접 지정할 수 있습니다.|Les frontières sont approximatives. Un GPS absent ne peut être retrouvé ; choisissez un lieu.|Grenzen sind vereinfacht. Fehlendes GPS lässt sich nicht wiederherstellen; Ort manuell zuordnen.|Los límites son aproximados. No se puede recuperar GPS ausente; asigna un lugar.|Os limites são aproximados. Não é possível recuperar GPS ausente; atribua um local.|الحدود تقريبية. لا يمكن استعادة GPS المفقود؛ عيّن المكان يدويًا.
Permission status: {0}|权限状态：{0}|權限狀態：{0}|許可状態：{0}|권한 상태: {0}|Autorisation : {0}|Berechtigung: {0}|Permiso: {0}|Permissão: {0}|حالة الإذن: {0}
Version {0} · Build {1}|版本 {0} · 构建 {1}|版本 {0} · 組建 {1}|バージョン{0}・ビルド{1}|버전 {0} · 빌드 {1}|Version {0} · Build {1}|Version {0} · Build {1}|Versión {0} · Compilación {1}|Versão {0} · Compilação {1}|الإصدار {0} · البناء {1}
Diagnostics|诊断信息|診斷資訊|診断|진단|Diagnostic|Diagnose|Diagnóstico|Diagnóstico|التشخيص
Photo unavailable|照片暂不可用|照片暫不可用|写真を表示できません|사진을 사용할 수 없음|Photo indisponible|Foto nicht verfügbar|Foto no disponible|Foto indisponível|الصورة غير متاحة
Download in Photos, then retry.|请在系统照片中下载原图后重试。|請在系統照片中下載原圖後重試。|写真アプリでダウンロードして再試行。|사진 앱에서 다운로드한 후 다시 시도하세요.|Téléchargez dans Photos, puis réessayez.|In Fotos laden, dann erneut versuchen.|Descarga en Fotos y reintenta.|Transfira em Fotos e tente novamente.|نزّلها في تطبيق الصور ثم أعد المحاولة.
No matching places|没有匹配地区|沒有符合的地區|一致する場所なし|일치하는 장소 없음|Aucun lieu trouvé|Keine passenden Orte|No hay lugares coincidentes|Sem locais correspondentes|لا توجد أماكن مطابقة
Clear search|清除搜索|清除搜尋|検索をクリア|검색 지우기|Effacer la recherche|Suche löschen|Borrar búsqueda|Limpar pesquisa|مسح البحث
Offline maps|离线地图|離線地圖|オフライン地図|오프라인 지도|Cartes hors ligne|Offlinekarten|Mapas sin conexión|Mapas offline|خرائط دون اتصال'''
def build():
    table={}
    for row in ROWS.splitlines():
        parts=row.split('|'); assert len(parts)==len(LANGS), row
        assert parts[0] not in table, parts[0]
        table[parts[0]]=dict(zip(LANGS,parts))
    out=ROOT/'App/Resources/Translations.json'
    out.write_text(json.dumps(table,ensure_ascii=False,indent=2),encoding='utf-8')
    permissions = [
        'Footprints reads photo locations to group your memories by place. Photos and locations are processed only on this device.',
        '足迹读取照片的拍摄位置，按地区整理回忆。照片和位置仅在本机处理。',
        '足跡讀取照片的拍攝位置，按地區整理回憶。照片和位置僅在本機處理。',
        '写真の撮影場所を読み取り、思い出を地域別に整理します。写真と位置情報はこの端末内でのみ処理されます。',
        '사진의 촬영 위치를 읽어 장소별로 추억을 정리합니다. 사진과 위치는 이 기기에서만 처리됩니다.',
        'Footprints lit les lieux de vos photos pour classer vos souvenirs. Les photos et positions sont traitées uniquement sur cet appareil.',
        'Footprints liest Fotostandorte, um Erinnerungen nach Orten zu ordnen. Fotos und Standorte werden nur auf diesem Gerät verarbeitet.',
        'Footprints lee la ubicación de las fotos para organizar tus recuerdos por lugar. Las fotos y ubicaciones se procesan solo en este dispositivo.',
        'O Footprints lê a localização das fotos para organizar as suas memórias por lugar. As fotos e localizações são processadas apenas neste dispositivo.',
        'يقرأ Footprints مواقع الصور لترتيب ذكرياتك حسب المكان. تتم معالجة الصور والمواقع على هذا الجهاز فقط.',
    ]
    for language, permission in zip(LANGS, permissions):
        folder=ROOT/'App/Resources'/f'{language}.lproj'; folder.mkdir(exist_ok=True)
        (folder/'InfoPlist.strings').write_text('"NSPhotoLibraryUsageDescription" = '+json.dumps(permission,ensure_ascii=False)+';\n',encoding='utf-8')
    print(f'{len(table)} messages in {len(LANGS)} languages')
if __name__=='__main__': build()
