كلية الإدارة والاقتصاد — صفحات "عن الكلية" الداخلية في UniWeb
================================================================

هذه الحزمة مبنية على مشروع UniWeb المرفوع سابقاً، وهي Patch إضافي مستقل عن حزمة الصفحة الرئيسية.
لا تستبدل الصفحة الرئيسية، ولا تنشئ Migration، ولا تعدل Models أو Controllers أو Routes، ولا تؤثر على بقية الكليات.

النتيجة
-------
1) إنشاء صفحات CMS داخلية عربية وإنكليزية للعناصر الآتية:
   - كلمة السيد العميد.
   - الرؤية والرسالة والأهداف.
   - الهيكل التنظيمي.
   - وصف المقررات.
   - وصف البرنامج الأكاديمي.
   - سياسة الجودة.
   - الاعتماد الأكاديمي.
   - مستجدات الاعتماد الأكاديمي.
   - أجندة الاعتماد الأكاديمي.
   - مجلس الكلية.
   - تواصل مع الكلية.

2) إنشاء صفحات عارض PDF داخلية:
   - الخطة الاستراتيجية 2024-2029.
   - تقرير التقييم الذاتي.

3) إعادة بناء قائمة "عن الكلية" بحيث:
   - ترتبط الصفحات بواسطة PageId الداخلي.
   - يظهر الاعتماد الأكاديمي بقائمة فرعية من المستوى الثالث.
   - لا تبقى روابط تشغيل إلى account.hilla-unc.edu.iq داخل قائمة الكلية.

4) تسجيل ملفي PDF في:
   - DocumentFolders.
   - DocumentFiles.
   - PageSections من نوع PdfViewer.

المسارات النهائية للملفات
-------------------------
UniWeb/wwwroot/uploads/colleges/administration-economics/documents/

الأسماء المطلوبة:
- administration-economics-strategic-plan-2024-2029.pdf
- administration-economics-self-evaluation-report.pdf

الملفات الموجودة في الحزمة
--------------------------
1) UniWeb/SQL/AdministrationEconomics_Internal_Pages_And_Documents.sql
   السكربت الرئيس الآمن والقابل لإعادة التنفيذ.

2) UniWeb/SQL/Verify_AdministrationEconomics_Internal_Pages.sql
   سكربت قراءة وفحص بعد التطبيق.

3) UniWeb/Tools/AdministrationEconomics/Download-AdministrationEconomicsDocuments.ps1
4) UniWeb/Tools/AdministrationEconomics/Download-AdministrationEconomicsDocuments.cmd
   أداة تنزيل ملفي PDF الرسميين، فحص توقيع PDF، حفظهما في wwwroot، وإنشاء سكربت اختياري لتحديث أحجام الملفات.

طريقة التطبيق
-------------
1. خذ نسخة احتياطية من قاعدة البيانات ومن مجلد المشروع.
2. افتح الحزمة وانسخ مجلد UniWeb فوق مجلد UniWeb في مشروعك، مع المحافظة على المسارات.
3. شغّل بالضغط المزدوج:
   UniWeb/Tools/AdministrationEconomics/Download-AdministrationEconomicsDocuments.cmd
4. افتح SSMS واختر قاعدة بيانات UniWeb الصحيحة.
5. نفّذ:
   UniWeb/SQL/AdministrationEconomics_Internal_Pages_And_Documents.sql
6. بعد نجاح التنزيل، نفّذ اختيارياً:
   UniWeb/SQL/AdministrationEconomics_Update_Document_Sizes.generated.sql
7. نفّذ سكربت التحقق:
   UniWeb/SQL/Verify_AdministrationEconomics_Internal_Pages.sql
8. نفّذ Clean Solution ثم Rebuild Solution.
9. شغّل الموقع واضغط Ctrl + F5.

المسارات المتوقعة
-----------------
/ar/pages/colleges/administration-economics/about/dean-message
/ar/pages/colleges/administration-economics/about/vision-mission-goals
/ar/pages/colleges/administration-economics/about/strategic-plan
/ar/pages/colleges/administration-economics/about/organizational-structure
/ar/pages/colleges/administration-economics/about/course-descriptions
/ar/pages/colleges/administration-economics/about/academic-program-description
/ar/pages/colleges/administration-economics/about/quality-policy
/ar/pages/colleges/administration-economics/about/academic-accreditation
/ar/pages/colleges/administration-economics/about/academic-accreditation/updates
/ar/pages/colleges/administration-economics/about/academic-accreditation/agenda
/ar/pages/colleges/administration-economics/about/academic-accreditation/self-evaluation-report
/ar/pages/colleges/administration-economics/about/college-council
/ar/pages/colleges/administration-economics/about/contact

تتوفر المسارات نفسها باللغة الإنكليزية بعد استبدال /ar/ بـ /en/.

ملاحظات مهمة
------------
- السكربت يحذف ويعيد إنشاء أبناء قائمة "عن الكلية" التابعة لكلية الإدارة والاقتصاد فقط، ولا يلمس قوائم الكليات الأخرى.
- الصفحات التي ينشئها السكربت تحمل SystemName يبدأ بـ college_administration_economics_.
- السكشنات التي يملكها السكربت تحمل InternalName يبدأ بـ admeco-internal-.
- صفحتا مستجدات وأجندة الاعتماد الأكاديمي مجهزتان للنشر، ولم تُضف إليهما تواريخ أو أرقام اعتماد غير موثقة.
- صفحة مجلس الكلية لا تتضمن أسماء أعضاء غير منشورة أو غير موثقة، ويمكن تحديثها من لوحة CMS.
- يجب أن تكون قيمة ExternalLinksRemainingInCollegeMenu في سكربت التحقق مساوية إلى 0.
- يجب أن يفتح ملفا PDF من المسارين المحليين داخل wwwroot بعد تشغيل أداة التنزيل وتنفيذ السكربت الرئيس.
