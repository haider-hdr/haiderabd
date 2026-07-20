/*
    UniWeb - College of Law
    Scientific Affairs internal pages, menu, and locally stored PDF

    تنفيذ آمن من SQL Server Management Studio (SSMS).
    - لا يوجد Seeder.
    - لا توجد Migration.
    - لا تعديل على Models أو Controllers أو Routes.
    - جميع عناصر قائمة الشؤون العلمية ترتبط بصفحات UniWeb داخلية بواسطة PageId.
    - ملف مدونة استخدام التقنيات الحديثة يُعرض بواسطة PdfViewer داخلي.
    - السكربت قابل لإعادة التنفيذ.
*/
SET NOCOUNT ON;
SET XACT_ABORT ON;

BEGIN TRY
    BEGIN TRANSACTION;

    DECLARE @Now datetime2(7) = SYSUTCDATETIME();
    DECLARE @CollegeId int;
    DECLARE @MenuId int;
    DECLARE @DocumentFolderId int;
    DECLARE @ScientificParentId int;
    DECLARE @ConferencesParentId int;
    DECLARE @ContributionsParentId int;

    IF OBJECT_ID(N'dbo.AcademicColleges', N'U') IS NULL
       OR OBJECT_ID(N'dbo.Pages', N'U') IS NULL
       OR OBJECT_ID(N'dbo.PageTranslations', N'U') IS NULL
       OR OBJECT_ID(N'dbo.PageSections', N'U') IS NULL
       OR OBJECT_ID(N'dbo.PageBlocks', N'U') IS NULL
       OR OBJECT_ID(N'dbo.SiteMenus', N'U') IS NULL
       OR OBJECT_ID(N'dbo.SiteMenuItems', N'U') IS NULL
       OR OBJECT_ID(N'dbo.DocumentFolders', N'U') IS NULL
       OR OBJECT_ID(N'dbo.DocumentFiles', N'U') IS NULL
    BEGIN
        THROW 52600, N'قاعدة البيانات لا تحتوي جداول UniWeb المطلوبة.', 1;
    END;

    SELECT TOP (1) @CollegeId = Id
    FROM dbo.AcademicColleges
    WHERE IsActive = 1
      AND (Code = N'LAW' OR Slug = N'colleges/law' OR NameAr = N'كلية القانون')
    ORDER BY CASE WHEN Code = N'LAW' THEN 0 ELSE 1 END, Id;

    IF @CollegeId IS NULL
        THROW 52601, N'لم يتم العثور على سجل كلية القانون.', 1;

    SELECT TOP (1) @MenuId = M.Id
    FROM dbo.SiteMenus M
    WHERE M.IsDeleted = 0
      AND
      (
          M.SystemName = N'college-law-menu'
          OR M.Id = (SELECT TOP (1) CustomMenuId FROM dbo.AcademicColleges WHERE Id = @CollegeId)
      )
    ORDER BY CASE WHEN M.SystemName = N'college-law-menu' THEN 0 ELSE 1 END, M.Id;

    IF @MenuId IS NULL
        THROW 52602, N'لم يتم العثور على قائمة كلية القانون.', 1;

    /* ================================================================
       1) تسجيل ملف مدونة استخدام التقنيات الحديثة محلياً
       ================================================================ */
    SELECT TOP (1) @DocumentFolderId = Id
    FROM dbo.DocumentFolders
    WHERE IsDeleted = 0
      AND AcademicCollegeId = @CollegeId
      AND Slug = N'college-law-scientific-documents'
    ORDER BY Id;

    IF @DocumentFolderId IS NULL
    BEGIN
        INSERT dbo.DocumentFolders
        (
            ParentId, NameAr, NameEn, Slug,
            DescriptionAr, DescriptionEn, IconClass,
            IsActive, IsDeleted, DisplayOrder,
            AcademicCollegeId, CreatedAtUtc
        )
        VALUES
        (
            NULL,
            N'وثائق الشؤون العلمية - كلية القانون',
            N'Scientific Affairs Documents - College of Law',
            N'college-law-scientific-documents',
            N'الوثائق والأدلة المرتبطة بالشؤون العلمية والمحفوظة محلياً داخل UniWeb.',
            N'Documents and guides related to scientific affairs and stored locally inside UniWeb.',
            N'bi bi-folder2-open',
            1, 0, 25,
            @CollegeId, @Now
        );
        SET @DocumentFolderId = CONVERT(int, SCOPE_IDENTITY());
    END
    ELSE
    BEGIN
        UPDATE dbo.DocumentFolders
        SET NameAr = N'وثائق الشؤون العلمية - كلية القانون',
            NameEn = N'Scientific Affairs Documents - College of Law',
            DescriptionAr = N'الوثائق والأدلة المرتبطة بالشؤون العلمية والمحفوظة محلياً داخل UniWeb.',
            DescriptionEn = N'Documents and guides related to scientific affairs and stored locally inside UniWeb.',
            IconClass = N'bi bi-folder2-open',
            AcademicCollegeId = @CollegeId,
            IsActive = 1,
            IsDeleted = 0,
            UpdatedAtUtc = @Now
        WHERE Id = @DocumentFolderId;
    END;

    DECLARE @ModernTechFilePath nvarchar(600) = N'/uploads/colleges/law/documents/college-of-law-modern-technologies-code.pdf';
    DECLARE @ModernTechFileName nvarchar(260) = N'college-of-law-modern-technologies-code.pdf';
    DECLARE @ModernTechDocumentFileId int;

    SELECT TOP (1) @ModernTechDocumentFileId = Id
    FROM dbo.DocumentFiles
    WHERE FilePath = @ModernTechFilePath
    ORDER BY Id;

    IF @ModernTechDocumentFileId IS NULL
    BEGIN
        INSERT dbo.DocumentFiles
        (
            DocumentFolderId, AcademicCollegeId,
            TitleAr, TitleEn, DescriptionAr, DescriptionEn,
            OriginalFileName, StoredFileName, FilePath,
            Extension, ContentType, FileSizeBytes,
            IsPdf, IsFeatured, IsActive, IsDeleted,
            DisplayOrder, CreatedAtUtc
        )
        VALUES
        (
            @DocumentFolderId, @CollegeId,
            N'مدونة كلية القانون لاستخدام التقنيات الحديثة',
            N'College of Law Code for the Use of Modern Technologies',
            N'المدونة الرسمية المنظمة للاستخدام المسؤول للتقنيات الحديثة في التعليم والبحث القانوني.',
            N'The official code governing the responsible use of modern technologies in legal education and research.',
            @ModernTechFileName, @ModernTechFileName, @ModernTechFilePath,
            N'.pdf', N'application/pdf', __MODERN_TECH_PDF_SIZE__,
            1, 1, 1, 0,
            90, @Now
        );
        SET @ModernTechDocumentFileId = CONVERT(int, SCOPE_IDENTITY());
    END
    ELSE
    BEGIN
        UPDATE dbo.DocumentFiles
        SET DocumentFolderId = @DocumentFolderId,
            AcademicCollegeId = @CollegeId,
            TitleAr = N'مدونة كلية القانون لاستخدام التقنيات الحديثة',
            TitleEn = N'College of Law Code for the Use of Modern Technologies',
            DescriptionAr = N'المدونة الرسمية المنظمة للاستخدام المسؤول للتقنيات الحديثة في التعليم والبحث القانوني.',
            DescriptionEn = N'The official code governing the responsible use of modern technologies in legal education and research.',
            OriginalFileName = @ModernTechFileName,
            StoredFileName = @ModernTechFileName,
            Extension = N'.pdf',
            ContentType = N'application/pdf',
            FileSizeBytes = __MODERN_TECH_PDF_SIZE__,
            IsPdf = 1,
            IsFeatured = 1,
            IsActive = 1,
            IsDeleted = 0,
            DisplayOrder = 90,
            UpdatedAtUtc = @Now
        WHERE Id = @ModernTechDocumentFileId;
    END;

    /* ================================================================
       2) تعريف الصفحات الداخلية
       ================================================================ */
    DECLARE @PagesData TABLE
    (
        PageKey nvarchar(100) NOT NULL PRIMARY KEY,
        SystemName nvarchar(180) NOT NULL,
        Slug nvarchar(360) NOT NULL,
        TitleAr nvarchar(300) NOT NULL,
        TitleEn nvarchar(300) NOT NULL,
        SummaryAr nvarchar(1000) NULL,
        SummaryEn nvarchar(1000) NULL,
        ContentAr nvarchar(max) NULL,
        ContentEn nvarchar(max) NULL,
        SectionType int NOT NULL,
        DisplayOrder int NOT NULL
    );

    INSERT @PagesData
    (
        PageKey, SystemName, Slug,
        TitleAr, TitleEn, SummaryAr, SummaryEn,
        ContentAr, ContentEn, SectionType, DisplayOrder
    )
    VALUES
    (
        N'faculty-research',
        N'college_law_faculty_research',
        N'colleges/law/scientific-affairs/faculty-research',
        N'بحوث التدريسيين',
        N'Faculty Research',
        N'البحوث العلمية المنشورة لأعضاء الهيئة التدريسية في كلية القانون.',
        N'Published scientific research by faculty members of the College of Law.',
        N'<div class="law-scientific-content"><div class="alert alert-info">تم تنظيم البيانات المنشورة في المصدر الرسمي وإزالة تكرار صفحة البحوث ذات الرابط المنتهي بعلامة #.</div><div class="table-responsive"><table class="table table-hover align-middle"><thead><tr><th>#</th><th>اسم التدريسي</th><th>عنوان البحث</th><th>المجلة</th><th>التصنيف</th><th>نوع البحث</th><th>السنة</th><th>الرابط</th></tr></thead><tbody><tr><td>1</td><td>م.م عدنان عباس حمزة محسن</td><td>الآثار القانونية للوعد بالتعاقد</td><td>مجلة كلية الإمام الأعظم</td><td>محلي</td><td>مفرد</td><td>2022</td><td><a class="btn btn-sm btn-outline-primary" target="_blank" rel="noopener" href="https://search.emarefa.net/ar/detail/BIM-1400716-%D8%A7%D9%84%D8%A2%D8%AB%D8%A7%D8%B1-%D8%A7%D9%84%D9%82%D8%A7%D9%86%D9%88%D9%86%D9%8A%D8%A9-%D9%84%D9%84%D9%88%D8%B9%D8%AF-%D8%A8%D8%A7%D9%84%D8%AA%D8%B9%D8%A7%D9%82%D8%AF">عرض البحث</a></td></tr><tr><td>2</td><td>عدنان عباس حمزة محسن</td><td>بطلان العقد المخالف للنظام العام والآداب: القاعدة الرومانية القديمة أنموذجاً</td><td>مجلة جامعة تكريت للحقوق</td><td>محلي</td><td>مفرد</td><td>2023</td><td><a class="btn btn-sm btn-outline-primary" target="_blank" rel="noopener" href="https://iasj.rdd.edu.iq/journals/uploads/2024/12/14/d40d7978f1d884cd03cae7b47907b5fb.pdf">عرض البحث</a></td></tr><tr><td>3</td><td>عدنان عباس حمزة محسن</td><td>مدى الترابط بين حق الحضانة وحق مشاهدة المحضون</td><td>مجلة رسالة الحقوق / جامعة كربلاء / كلية القانون</td><td>محلي</td><td>مشترك</td><td>2023</td><td><a class="btn btn-sm btn-outline-primary" target="_blank" rel="noopener" href="https://search.emarefa.net/ar/detail/BIM-1641013-%D9%85%D8%AF%D9%89-%D8%A7%D9%84%D8%AA%D8%B1%D8%A7%D8%A8%D8%B7-%D8%A8%D9%8A%D9%86-%D8%AD%D9%82-%D8%A7%D9%84%D8%AD%D8%B6%D8%A7%D9%86%D8%A9-%D9%88%D8%AD%D9%82-%D9%85%D8%B4%D8%A7%D9%87%D8%AF%D8%A9-%D8%A7%D9%84%D9%85%D8%AD%D8%B6%D9%88%D9%86">عرض البحث</a></td></tr><tr><td>4</td><td>رباب محمود عامر الكسار</td><td>التنظيم القانوني للهجمات السيبرانية على المنشآت ذات القوى الخطرة</td><td>مجلة كلية التربية للبنات للعلوم الإنسانية</td><td>محلي</td><td>مشترك</td><td>2017</td><td><a class="btn btn-sm btn-outline-primary" target="_blank" rel="noopener" href="https://journal.uokufa.edu.iq/index.php/ewjh/article/view/9072">عرض البحث</a></td></tr><tr><td>5</td><td>رباب محمود عامر الكسار</td><td>التقاضي في المحكمة الإلكترونية</td><td>مجلة كلية التربية للبنات للعلوم الإنسانية</td><td>محلي</td><td>مفرد</td><td>2020</td><td><a class="btn btn-sm btn-outline-primary" target="_blank" rel="noopener" href="https://journal.uokufa.edu.iq/index.php/ewjh/article/view/8953">عرض البحث</a></td></tr><tr><td>6</td><td>محمد علي سالم جاسم</td><td>آليات الحد من العنف الأسري</td><td>مجلة المعهد</td><td>محلي</td><td>مشترك</td><td>2023</td><td><a class="btn btn-sm btn-outline-primary" target="_blank" rel="noopener" href="https://doi.org/10.61353/ma.0150001">عرض البحث</a></td></tr><tr><td>7</td><td>قتيبة جلولاء شنين علوة الجنابي</td><td>الاعتراف المعيب وأثره في الحكم</td><td>مجلة ننار للعلوم الإنسانية والاجتماعية</td><td>محلي</td><td>مفرد</td><td>2024</td><td><a class="btn btn-sm btn-outline-primary" target="_blank" rel="noopener" href="https://nanar-journal.hilla-unc.edu.iq/index.php/nanar/article/view/45">عرض البحث</a></td></tr><tr><td>8</td><td>م.م شذى علي أحمد</td><td>إضراب الموظف في المرافق العامة في التشريعات العراقية</td><td>كلية الإمام الكاظم للعلوم الإسلامية / أقسام بابل</td><td>محلي</td><td>مفرد</td><td>2023</td><td><a class="btn btn-sm btn-outline-primary" target="_blank" rel="noopener" href="https://iku.edu.iq/storage/6410/66b88132e3471-%D8%A8%D8%AD%D9%88%D8%AB_%D8%A7%D9%84%D9%85%D8%A4%D8%AA%D9%85%D8%B1_%D8%A7%D9%84%D8%AF%D9%88%D9%84%D9%8A_%D8%A7%D9%84%D8%B1%D8%A7%D8%A8%D8%B9_%D8%A3%D9%82%D8%B3%D8%A7%D9%85_%D8%A8%D8%A7%D8%A8%D9%84.pdf">عرض البحث</a></td></tr><tr><td>9</td><td>م.م شذى علي أحمد</td><td>دور منظمات المجتمع المدني في مكافحة التطرف الفكري</td><td>مجلة المحقق الحلي للعلوم القانونية والسياسية</td><td>محلي</td><td>مفرد</td><td>2025</td><td><a class="btn btn-sm btn-outline-primary" target="_blank" rel="noopener" href="https://iasj.rdd.edu.iq/journals/uploads/2025/02/26/6c5c598ddc03b82ae047064e4161ee1e.pdf">عرض البحث</a></td></tr><tr><td>10</td><td>م.د عدنان عباس الراجحي</td><td>مدى الترابط بين حق الحضانة وحق مشاهدة المحضون</td><td>مجلة رسالة الحقوق / جامعة كربلاء / كلية القانون</td><td>محلي</td><td>مفرد</td><td>2023</td><td><a class="btn btn-sm btn-outline-primary" target="_blank" rel="noopener" href="https://scholar.google.com/citations?view_op=view_citation&amp;hl=ar&amp;user=QirbYrUAAAAJ&amp;citation_for_view=QirbYrUAAAAJ:9yKSN-GCB0IC">عرض البحث</a></td></tr><tr><td>11</td><td>أ.د حيدر حسين الكريطي</td><td>روح القانون الجنائي: دراسة تحليلية في ضوء مبادئ العدالة الجنائية</td><td>مجلة المحقق الحلي للعلوم القانونية والسياسية</td><td>محلي</td><td>مفرد</td><td>2024</td><td><a class="btn btn-sm btn-outline-primary" target="_blank" rel="noopener" href="https://iasj.rdd.edu.iq/journals/uploads/2025/02/26/78389ed7a0d1859f2bf3da1eb0418b0c.pdf">عرض البحث</a></td></tr><tr><td>12</td><td>غير مذكور في المصدر</td><td>المشتبه به في النظم الجزائية الإجرائية الحديثة</td><td>مجلة كلية الكوت الجامعة</td><td>محلي</td><td>مفرد</td><td>2024</td><td><a class="btn btn-sm btn-outline-primary" target="_blank" rel="noopener" href="https://jh.alkutcollege.edu.iq/article_24461_216b2086f71122f4881278181e981243.pdf">عرض البحث</a></td></tr></tbody></table></div></div>',
        N'<div class="law-scientific-content"><p>This page presents the faculty research records published by the official College source. Research titles and journal names are translated for navigation while official article links are retained.</p><div class="table-responsive"><table class="table table-hover align-middle"><thead><tr><th>#</th><th>Faculty Member</th><th>Research Title</th><th>Journal</th><th>Scope</th><th>Authorship</th><th>Year</th></tr></thead><tbody><tr><td>1</td><td>Adnan Abbas Hamza Mohsen</td><td>Legal Effects of a Promise to Contract</td><td>Journal of Al-Imam Al-Aadham College</td><td>Local</td><td>Single</td><td>2022</td></tr><tr><td>2</td><td>Adnan Abbas Hamza Mohsen</td><td>Invalidity of a Contract Contrary to Public Order and Morals</td><td>Tikrit University Journal of Law</td><td>Local</td><td>Single</td><td>2023</td></tr><tr><td>3</td><td>Adnan Abbas Hamza Mohsen</td><td>The Relationship Between Custody and Visitation Rights</td><td>Risalat Al-Huqooq Journal</td><td>Local</td><td>Joint</td><td>2023</td></tr><tr><td>4</td><td>Rabab Mahmoud Amer Al-Kassar</td><td>Legal Regulation of Cyberattacks on High-Risk Facilities</td><td>Journal of the College of Education for Women</td><td>Local</td><td>Joint</td><td>2017</td></tr><tr><td>5</td><td>Rabab Mahmoud Amer Al-Kassar</td><td>Litigation in the Electronic Court</td><td>Journal of the College of Education for Women</td><td>Local</td><td>Single</td><td>2020</td></tr><tr><td>6</td><td>Mohammed Ali Salim Jassim</td><td>Mechanisms for Reducing Domestic Violence</td><td>Al-Maahad Journal</td><td>Local</td><td>Joint</td><td>2023</td></tr><tr><td>7</td><td>Qutaiba Jalawla Shneen Al-Janabi</td><td>Defective Confession and Its Effect on Judgment</td><td>Nanar Journal</td><td>Local</td><td>Single</td><td>2024</td></tr><tr><td>8</td><td>Shatha Ali Ahmed</td><td>Public Employee Strike in Iraqi Legislation</td><td>Imam Al-Kadhim College</td><td>Local</td><td>Single</td><td>2023</td></tr><tr><td>9</td><td>Shatha Ali Ahmed</td><td>The Role of Civil Society Organisations in Combating Intellectual Extremism</td><td>Al-Muhaqiq Al-Hilli Journal</td><td>Local</td><td>Single</td><td>2025</td></tr><tr><td>10</td><td>Adnan Abbas Al-Rajihi</td><td>The Relationship Between Custody and Visitation Rights</td><td>Risalat Al-Huqooq Journal</td><td>Local</td><td>Single</td><td>2023</td></tr><tr><td>11</td><td>Haider Hussein Al-Kuraiti</td><td>The Spirit of Criminal Law: An Analytical Study in Light of Criminal Justice</td><td>Al-Muhaqiq Al-Hilli Journal</td><td>Local</td><td>Single</td><td>2024</td></tr><tr><td>12</td><td>Not stated in the source</td><td>The Suspect in Modern Criminal Procedural Systems</td><td>Al-Kut University College Journal</td><td>Local</td><td>Single</td><td>2024</td></tr></tbody></table></div></div>',
        2, 10
    ),
    (
        N'graduation-research',
        N'college_law_graduation_research',
        N'colleges/law/scientific-affairs/graduation-research',
        N'بحوث التخرج',
        N'Graduation Research',
        N'بحوث تخرج طلبة كلية القانون وإشراف أعضاء الهيئة التدريسية كما نُشرت في المصدر الرسمي.',
        N'College of Law student graduation research and faculty supervision as published in the official source.',
        N'<div class="law-scientific-content"><div class="alert alert-warning">عُرضت السنوات والعناوين كما وردت في الجدول الرسمي، بما في ذلك القيم التي تحتاج إلى تدقيق إداري من الكلية.</div><div class="table-responsive"><table class="table table-striped table-hover align-middle"><thead><tr><th>ت</th><th>اسم التدريسي</th><th>اسم الطالب</th><th>السنة الدراسية</th><th>عنوان البحث</th></tr></thead><tbody><tr><td>1</td><td>م.م شذى علي أحمد</td><td>فاطمة عباس مهدي</td><td>2024/2025</td><td>دور الفساد الإداري في مكافحة الإرهاب وطرق مكافحته</td></tr><tr><td>2</td><td>م.م شذى علي أحمد</td><td>علي عبودي هادي إبراهيم</td><td>2024/2025</td><td>المسؤولية التأديبية للموظف العام</td></tr><tr><td>3</td><td>م.م شذى علي أحمد</td><td>عمار ساهي</td><td>2024/2025</td><td>دور الإدارة في إبطال القرار الإداري</td></tr><tr><td>4</td><td>م.م شذى علي أحمد</td><td>علي قحطان مروان</td><td>2024/2025</td><td>إجراءات فرض العقوبة الانضباطية في العراق</td></tr><tr><td>5</td><td>م.م شذى علي أحمد</td><td>عيسى محي جبر</td><td>2023/2024</td><td>رقابة القضاء الإداري على السلطة التقديرية</td></tr><tr><td>6</td><td>م.م شذى علي أحمد</td><td>فيصل سعيد يلسر</td><td>2023/2024</td><td>إنهاء القرار الإداري بالإرادة المنفردة للإدارة</td></tr><tr><td>7</td><td>م.م شذى علي أحمد</td><td>قاسم طالب يوسف</td><td>2023/2024</td><td>انتهاء القرار الإداري</td></tr><tr><td>8</td><td>م.م شذى علي أحمد</td><td>محسن كريم حمزة</td><td>2023/2024</td><td>المرافق العامة</td></tr><tr><td>9</td><td>م.م شذى علي أحمد</td><td>محمد إياد مطلك</td><td>2023/2024</td><td>التحولات في القانون الإداري في ظل الأزمات</td></tr><tr><td>10</td><td>م.م شذى علي أحمد</td><td>هاجر نعيم</td><td>2023/2024</td><td>الرشوة في القوانين العراقية: معايير الجريمة وعواقبها</td></tr><tr><td>11</td><td>م.م أماني حافظ إبراهيم</td><td>هند عبد زيد مجيد</td><td>2024/2025</td><td>المسؤولية المدنية لشركات النفط العاملة في العراق عن التلوث البيئي</td></tr><tr><td>12</td><td>م.م أماني حافظ إبراهيم</td><td>نجاح حسن حسين</td><td>2025/2024</td><td>جريمة تزييف العملة في القانون العراقي</td></tr><tr><td>13</td><td>م.م أماني حافظ إبراهيم</td><td>ياسين عبد الله عاشور</td><td>2025/2024</td><td>المسؤولية الناجمة عن استخدام أبراج الاتصالات والإنترنت</td></tr><tr><td>14</td><td>م.م أماني حافظ إبراهيم</td><td>مهيمن محمد محسن</td><td>2025/2024</td><td>جرائم الاعتداء على الموظف العام</td></tr><tr><td>15</td><td>م.م رامي هاتف عبيد</td><td>محمد عبد الله عاشور</td><td>2025/2024</td><td>كشف الدلالة وأثره في تعزيز اعتراف المتهم</td></tr><tr><td>16</td><td>م.م رامي هاتف عبيد</td><td>محمد إبراهيم محمد</td><td>2025/2024</td><td>الاضطرابات العقلية وتأثيرها على المسؤولية الجنائية</td></tr><tr><td>17</td><td>م.م رامي هاتف عبيد</td><td>محمد عبد العباس عطية</td><td>2025/2025</td><td>المسؤولية الجنائية عن العنف الأسري في العراق</td></tr><tr><td>18</td><td>م.م رامي هاتف عبيد</td><td>محمد عبد حسن</td><td>2025/2024</td><td>ضمانات المتهم أثناء مرحلة التحقيق الابتدائي</td></tr><tr><td>19</td><td>م.م رامي هاتف عبيد</td><td>محمد إبراهيم كامل</td><td>2025/2024</td><td>المسؤولية الجزائية للمتنمر عبر مواقع التواصل الاجتماعي</td></tr><tr><td>20</td><td>أ.د محمد علي سالم</td><td>فاهم عزيز حمزة</td><td>2023/2024</td><td>جريمة تعاطي المخدرات</td></tr><tr><td>21</td><td>أ.د محمد علي سالم</td><td>صفا عبد الكريم</td><td>2023/2025</td><td>المسؤولية الجزائية للصيدلي عن أخطائه المهنية</td></tr><tr><td>22</td><td>أ.د محمد علي سالم</td><td>ندى إسماعيل جفات</td><td>2023/2026</td><td>إعادة المحاكمة</td></tr><tr><td>23</td><td>م.م أسيل رزاق صيهود</td><td>علي حيدر حسن</td><td>2023/2027</td><td>التظهير في الأوراق التجارية وأنواعه</td></tr><tr><td>24</td><td>م.م أسيل رزاق صيهود</td><td>مصطفى سالم مطر</td><td>2023/2028</td><td>قبول الحوالة التجارية بالتدخل</td></tr><tr><td>25</td><td>م.م أسيل رزاق صيهود</td><td>عمار محمد حمود</td><td>2023/2029</td><td>النظام القانوني لحوالة الدين</td></tr><tr><td>26</td><td>أ.م.د يوسف سعدون محمد</td><td>مرتضى محمد بدر</td><td>2023/2030</td><td>إزالة الشيوع في القانون العراقي</td></tr><tr><td>27</td><td>م.د زينب رزاق مصطفى</td><td>ياسين سعدون</td><td>2023/2031</td><td>أحكام القيود الاتفاقية الواردة على تداول الأسهم في القانون العراقي</td></tr><tr><td>28</td><td>م.د زينب رزاق مصطفى</td><td>معتز كريم علوان</td><td>2023/2032</td><td>أحكام تداول شركات المساهمة في القانون العراقي</td></tr><tr><td>29</td><td>م.د علي محمد أمنيف</td><td>رونف طالب حسين</td><td>2023/2033</td><td>التعددية الحزبية وقانون إدارة الدولة العراقية</td></tr><tr><td>30</td><td>م.د كرار محمد الغزالي</td><td>عباس أحمد موهان</td><td>2023/2034</td><td>التعهد بنقل ملكية العقار</td></tr><tr><td>31</td><td>م.د كرار محمد الغزالي</td><td>نرجس هيثم</td><td>2023/2035</td><td>نظرية الظروف الطارئة</td></tr><tr><td>32</td><td>م.د كرار محمد الغزالي</td><td>طاهر نجم خيري</td><td>2023/2036</td><td>دور الإرادة المنفردة في تعديل العقد</td></tr><tr><td>33</td><td>م.د كرار محمد الغزالي</td><td>سيف طارق</td><td>2023/2037</td><td>سلطة القاضي في تحديد نطاق العقد</td></tr><tr><td>34</td><td>أ.د علاء الحسيني</td><td>قاسم علي مهدي</td><td>2023/2038</td><td>الحماية الإدارية للبيئة المائية</td></tr><tr><td>35</td><td>م.د ضرغام رشيد نوري</td><td>محمد عصام محمد رضا</td><td>2023/2039</td><td>الحماية القانونية للأموال العامة</td></tr><tr><td>36</td><td>م.د عدنان عباس حمزة</td><td>حسين عباس مزهر</td><td>2023/2040</td><td>المسؤولية القانونية لطبيب التخدير</td></tr><tr><td>37</td><td>م.د عدنان عباس حمزة</td><td>طاهر أحمد</td><td>2023/2041</td><td>ملكية الشقق والطوابق</td></tr><tr><td>38</td><td>م.م حسن تحسين علي</td><td>ثائر عقيل جابر</td><td>2023/2042</td><td>جرائم القذف والسب في قانون العقوبات العراقي</td></tr><tr><td>39</td><td>م.م حسن تحسين علي</td><td>علي جمعة عليوي</td><td>2023/2043</td><td>دور الطالب الجامعي في الإخبار عن الجرائم</td></tr><tr><td>40</td><td>القاضي المتقاعد قتيبة جلولاء</td><td>ماهر علي جاسم</td><td>2024/2025</td><td>القيمة القانونية لإفادة المخبر السري في القانون العراقي</td></tr><tr><td>41</td><td>القاضي المتقاعد قتيبة جلولاء</td><td>قيصر حميد رزيج</td><td>2024/2025</td><td>إثبات الطلاق عبر وسائل الاتصال الحديثة في التشريع العراقي</td></tr><tr><td>42</td><td>القاضي المتقاعد قتيبة جلولاء</td><td>قيصر سالم مشعل</td><td>2024/2025</td><td>جريمة الاتجار بالبشر في التشريع العراقي</td></tr><tr><td>43</td><td>القاضي المتقاعد قتيبة جلولاء</td><td>فالح صادق حسين</td><td>2024/2025</td><td>الوسائل غير المشروعة في استجواب المتهم</td></tr></tbody></table></div></div>',
        N'<div class="law-scientific-content"><p>This page contains the graduation-research records published by the official College source. Academic-year values are preserved as published and may require administrative verification.</p><div class="alert alert-info">The Arabic version contains the complete official table of 43 records. Student and supervisor names remain available there to preserve their official spelling.</div></div>',
        2, 20
    ),
    (
        N'conference-hilla',
        N'college_law_ip_it_conference_hilla',
        N'colleges/law/scientific-affairs/conferences/ip-it-hilla',
        N'مؤتمر حقوق الملكية الفكرية وتكنولوجيا المعلومات',
        N'Intellectual Property and Information Technology Conference',
        N'المؤتمر الدولي الأول الذي نظمته كلية القانون بالتعاون مع كلية العلوم في جامعة الحلة.',
        N'The first international conference organised by the College of Law in cooperation with the College of Science at the University of Hilla.',
        N'<div class="law-scientific-content"><p class="lead">جامعة الحلة تطلق المؤتمر الدولي الأول حول حقوق الملكية الفكرية وتكنولوجيا المعلومات بمشاركة وفد أكاديمي دولي.</p><p>برعاية رئيس جامعة الحلة الأستاذ الدكتور عقيل السعدي، انطلقت فعاليات المؤتمر الدولي الأول حول حقوق الملكية الفكرية وتكنولوجيا المعلومات، الذي نظمته كلية القانون بالتعاون مع كلية العلوم، بمشاركة شخصيات أكاديمية وباحثين محليين ودوليين.</p><p>شهد المؤتمر حضور وفد من جامعة جهرم الإيرانية برئاسة الأستاذ الدكتور محمد عباس زاده، رئيس الجامعة، وبمشاركة المساعدين للشؤون العلمية والإدارية، إلى جانب الملحق الثقافي في القنصلية الإيرانية وعدد من الشخصيات الأكاديمية والرسمية.</p><p>تناولت الجلسات العلمية والحوارية قضايا حقوق الملكية الفكرية والتحديات القانونية والتقنية في عصر الرقمنة، كما أكدت الكلمات أهمية التعاون العلمي الدولي وتطوير البحوث المشتركة في مجالات التكنولوجيا الحديثة.</p><p>اختُتم المؤتمر بتكريم المشاركين والمساهمين في إنجاح الحدث تقديراً لإسهاماتهم العلمية والتنظيمية.</p></div>',
        N'<div class="law-scientific-content"><p class="lead">The University of Hilla launched its first international conference on Intellectual Property Rights and Information Technology with international academic participation.</p><p>Under the patronage of University President Prof. Aqeel Al-Saadi, the College of Law organised the conference in cooperation with the College of Science. Academic figures and local and international researchers participated.</p><p>The conference welcomed a delegation from Jahrom University headed by its President, Prof. Mohammad Abbaszadeh, together with scientific and administrative representatives and other academic and official guests.</p><p>Parallel scientific and dialogue sessions addressed intellectual-property issues and legal and technical challenges in the digital era, highlighting international cooperation and joint research.</p><p>Participants and contributors were honoured at the conclusion of the conference.</p></div>',
        2, 30
    ),
    (
        N'conference-shiraz',
        N'college_law_ip_it_conference_shiraz',
        N'colleges/law/scientific-affairs/conferences/ip-it-shiraz',
        N'حقوق الملكية الفكرية وتكنولوجيا المعلومات في جامعة شيراز',
        N'Intellectual Property and Information Technology Conference in Shiraz',
        N'مشاركة وفد من جامعة الحلة في مؤتمر علمي دولي بمدينة شيراز.',
        N'Participation of a University of Hilla delegation in an international scientific conference in Shiraz.',
        N'<div class="law-scientific-content"><p class="lead">وفد من جامعة الحلة يشارك في مؤتمر علمي دولي حول حقوق الملكية الفكرية وتكنولوجيا المعلومات في شيراز.</p><p>شارك وفد من أساتذة جامعة الحلة في المؤتمر العلمي الدولي الذي أقامه مركز البحوث والدراسات التابع لجامعة جهرم في مدينة شيراز تحت عنوان حقوق الملكية الفكرية وتكنولوجيا المعلومات.</p><h3>وفد الجامعة</h3><ul><li>الأستاذ الدكتور أحمد سليم الصفار.</li><li>الأستاذ المساعد الدكتور عدنان عباس حمزة.</li><li>المدرس الدكتور حيدر جاسم طاهر الشكري.</li></ul><p>شهد المؤتمر مشاركة أكاديميين وباحثين من تخصصات متعددة، ولا سيما الطاقة الذرية، وحماية حقوق المرأة، والتقنيات الطبية، وعلوم الذكاء الاصطناعي.</p><p>سلطت البحوث الضوء على التطور في تكنولوجيا المعلومات وأهمية بناء بيئة قانونية تحمي حقوق الملكية الفكرية، وتطوير المنظومة التشريعية بما يواكب التطور التقني، وتفعيل دور الجهات المختصة في مراقبة الاعتداءات الرقمية ومنعها.</p></div>',
        N'<div class="law-scientific-content"><p class="lead">A University of Hilla delegation participated in an international scientific conference on intellectual property and information technology in Shiraz.</p><p>The conference was organised by the Research and Studies Centre of Jahrom University and brought together researchers from fields including atomic energy, women rights, medical technologies, and artificial intelligence.</p><h3>University Delegation</h3><ul><li>Prof. Ahmed Salim Al-Saffar.</li><li>Asst. Prof. Adnan Abbas Hamza.</li><li>Lect. Haider Jassim Taher Al-Shukri.</li></ul><p>Presented research highlighted the rapid development of information technology, the need for a suitable legal environment protecting intellectual property, legislative development, and stronger monitoring of digital infringements.</p></div>',
        2, 40
    ),
    (
        N'course-descriptions',
        N'college_law_course_descriptions',
        N'colleges/law/scientific-affairs/course-descriptions',
        N'وصف المقررات الدراسية',
        N'Course Descriptions',
        N'بوابة داخلية لوصف المقررات الدراسية المعلنة لمراحل برنامج القانون.',
        N'An internal gateway to the published course descriptions for stages of the Law programme.',
        N'<div class="law-scientific-content"><div class="alert alert-info">آخر إشارة منشورة في المصدر: وصف المقررات جديد بتاريخ 3-3-2026.</div><div class="row g-4"><div class="col-md-4"><div class="card h-100"><div class="card-body"><h3>المرحلة الثانية</h3><p>قسم مهيأ لإضافة وصف المقررات المعتمد وملفاته من خلال نظام المستندات.</p></div></div></div><div class="col-md-4"><div class="card h-100"><div class="card-body"><h3>المرحلة الثالثة</h3><p>قسم مهيأ لإضافة وصف المقررات المعتمد وملفاته من خلال نظام المستندات.</p></div></div></div><div class="col-md-4"><div class="card h-100"><div class="card-body"><h3>المرحلة الرابعة</h3><p>قسم مهيأ لإضافة وصف المقررات المعتمد وملفاته من خلال نظام المستندات.</p></div></div></div></div><p class="text-muted mt-4">لم تظهر ملفات مقررات قابلة للتنزيل ضمن الصفحة الرسمية التي أمكن الوصول إليها؛ لذلك لم تُنشأ روابط أو ملفات غير موجودة.</p></div>',
        N'<div class="law-scientific-content"><div class="alert alert-info">Latest official reference: updated course descriptions dated 3 March 2026.</div><div class="row g-4"><div class="col-md-4"><div class="card h-100"><div class="card-body"><h3>Second Stage</h3><p>Ready for approved course-description documents through the UniWeb document system.</p></div></div></div><div class="col-md-4"><div class="card h-100"><div class="card-body"><h3>Third Stage</h3><p>Ready for approved course-description documents through the UniWeb document system.</p></div></div></div><div class="col-md-4"><div class="card h-100"><div class="card-body"><h3>Fourth Stage</h3><p>Ready for approved course-description documents through the UniWeb document system.</p></div></div></div></div><p class="text-muted mt-4">No downloadable course files were exposed by the accessible official page, so no missing or invented files have been linked.</p></div>',
        2, 50
    ),
    (
        N'lectures',
        N'college_law_academic_lectures',
        N'colleges/law/scientific-affairs/lectures',
        N'المحاضرات الدراسية',
        N'Academic Lectures',
        N'صفحة داخلية لتنظيم المحاضرات والمواد الدراسية الخاصة بكلية القانون.',
        N'An internal page for organising College of Law lectures and learning materials.',
        N'<div class="law-scientific-content"><p>تم إنشاء هذه الصفحة داخل UniWeb لتجميع المحاضرات والمواد الدراسية وربطها بنظام المستندات عند اعتماد الملفات.</p><div class="alert alert-warning">الصفحة القديمة المرسلة لم تعرض ملفات محاضرات قابلة للنقل في المحتوى الذي أمكن الوصول إليه؛ لذلك لم تُضف روابط خارجية أو ملفات وهمية.</div><h3>طريقة الإدارة</h3><ul><li>رفع كل محاضرة من مكتبة المستندات.</li><li>ربطها بكلية القانون والمرحلة والمادة.</li><li>إظهار نوع الملف وحجمه وزر العرض أو التنزيل.</li><li>تحديث المحتوى من لوحة الإدارة دون تعديل ملفات Razor.</li></ul></div>',
        N'<div class="law-scientific-content"><p>This internal UniWeb page is prepared to organise College lectures and learning materials through the document system.</p><div class="alert alert-warning">The supplied legacy page did not expose transferable lecture files in the content that could be accessed, so no external or fabricated files have been added.</div><h3>Management Workflow</h3><ul><li>Upload each lecture through the document library.</li><li>Associate it with the College, stage, and course.</li><li>Display file type, size, and view or download actions.</li><li>Maintain the content through the administration panel.</li></ul></div>',
        2, 60
    ),
    (
        N'external-contracting',
        N'college_law_external_contracting_rules',
        N'colleges/law/scientific-affairs/external-contracting-rules',
        N'ضوابط التعاقد مع جهات خارجية',
        N'Rules for Contracting with External Entities',
        N'صفحة داخلية لضوابط وإجراءات التعاقد العلمي والمهني مع الجهات الخارجية.',
        N'An internal page for rules and procedures governing scientific and professional contracting with external entities.',
        N'<div class="law-scientific-content"><p>تم تجهيز هذه الصفحة داخل UniWeb بدلاً من إبقاء رابط خارجي إلى الموقع القديم.</p><div class="alert alert-warning">تعذر استخراج نص ضوابط مستقل وموثوق من الصفحة الرسمية المرسلة؛ لذلك لم تُكتب تعليمات أو أحكام غير موجودة في المصدر.</div><p>يمكن إضافة النص المعتمد أو ملف التعليمات من لوحة إدارة المحتوى وربطه بمكتبة مستندات كلية القانون، مع الإبقاء على رابط الصفحة الداخلي نفسه.</p></div>',
        N'<div class="law-scientific-content"><p>This page has been prepared inside UniWeb instead of retaining a runtime link to the legacy website.</p><div class="alert alert-warning">A separate verified text of the contracting rules could not be extracted from the supplied official page, so no rules have been invented.</div><p>The approved text or document can be added through the CMS and linked to the College document library while retaining this internal route.</p></div>',
        2, 70
    ),
    (
        N'promotion-instructions',
        N'college_law_scientific_promotion_instructions',
        N'colleges/law/scientific-affairs/scientific-promotion-instructions',
        N'تعليمات الترقية العلمية',
        N'Scientific Promotion Instructions',
        N'متطلبات الترقية العلمية وفق تعليمات الترقيات العلمية رقم 167 لسنة 2017 كما نُشرت في المصدر الرسمي.',
        N'Scientific promotion requirements under Instruction No. 167 of 2017 as published by the official source.',
        N'<div class="law-scientific-content"><p class="lead">متطلبات الترقية العلمية لجميع المراتب العلمية وفق تعليمات الترقيات رقم 167 لسنة 2017.</p><ol><li>كتاب إحالة المعاملة إلى شعبة شؤون الترقيات المركزية.</li><li>طلب ترويج معاملة الترقية موقع ومؤرخ من صاحب الترقية.</li><li>الأوامر الجامعية والإدارية بمنح اللقب العلمي وشهادتي الماجستير والدكتوراه.</li><li>استمارات تدقيق المعلومات والترقيات العلمية رقم 1 ورقم 2 وترشيح الخبراء.</li><li>الأمر الإداري بتشكيل لجنة الاستلال، ومحضر الاستلال النصي، ونتيجة الاستلال الإلكتروني للبحوث المنشورة بعد 2/1/2016.</li><li>تأييد تسجيل البحوث والتعهد بعدم الاستلال مصادقاً من الوحدة القانونية.</li><li>تقييمات الأداء السنوية المتتالية أو تأييد القسم العلمي عند عدم توفر تقييم سنة معينة.</li><li>محضر مجلس الكلية مصادقاً من رئيس الجامعة، وأوامر التعيين والمباشرة.</li><li>البحوث المقدمة للترقية السابقة والحالية بصيغة ورقية وPDF.</li><li>للمدرس: بحث في الاختصاص العام أو الدقيق ويكون أحد البحوث منفرداً.</li><li>للأستاذ المساعد: بحثان في الاختصاص الدقيق ويكون أحدهما منفرداً.</li><li>للأستاذ: جميع البحوث في الاختصاص الدقيق ويكون أحدها منفرداً.</li><li>يجوز الإعفاء من شرط البحث المنفرد وفق الشروط المنشورة، ومنها أن يكون المتقدم الباحث الأول وألا يكون البحث مستلاً من رسائل أو أطاريح أشرف عليها وأن يكون منشوراً في مجلة مسجلة في Scopus.</li><li>بحث منشور واحد على الأقل لمرتبة مدرس، وبحثان منشوران للأستاذ المساعد والأستاذ، مع مراعاة شروط بحوث Scopus.</li><li>دورة سلامة اللغة العربية، ودورة طرائق التدريس للمتقدم إلى مرتبة مدرس.</li><li>تقرير الرصانة العلمية لبحوث Scopus وتأييدات قبول النشر للبحوث غير المنشورة.</li><li>السيرة الذاتية المصادق عليها واستمارات تقييم الخبراء وخلاصة الترقية.</li></ol><h3>النقاط المطلوبة</h3><div class="table-responsive"><table class="table table-bordered"><thead><tr><th>المرتبة</th><th>المجموع</th><th>الجدول رقم 1</th><th>الجدول رقم 2</th></tr></thead><tbody><tr><td>مدرس</td><td>70</td><td>46</td><td>24</td></tr><tr><td>أستاذ مساعد</td><td>80</td><td>52</td><td>28</td></tr><tr><td>أستاذ</td><td>90</td><td>59</td><td>31</td></tr></tbody></table></div><p>تُرفق رسالة الماجستير وأطروحة الدكتوراه لصاحب الترقية وللباحث المشترك عند تقديم بحوث مشتركة.</p></div>',
        N'<div class="law-scientific-content"><p class="lead">Scientific promotion requirements for all academic ranks under Promotion Instruction No. 167 of 2017.</p><ul><li>Official referral, signed application, academic-title orders, degree-award orders, and appointment records.</li><li>Information-audit, promotion, expert-nomination, plagiarism, and expert-evaluation forms.</li><li>Previous and current promotion research in paper and PDF formats.</li><li>Research-specialisation and sole-authorship requirements according to the requested academic rank.</li><li>Publication and Scopus-indexing requirements as stated in the official instructions.</li><li>Arabic-language safety course and teaching-methods course where applicable.</li><li>Continuous annual performance evaluations or an official departmental confirmation.</li></ul><div class="table-responsive"><table class="table table-bordered"><thead><tr><th>Rank</th><th>Total Points</th><th>Table 1</th><th>Table 2</th></tr></thead><tbody><tr><td>Lecturer</td><td>70</td><td>46</td><td>24</td></tr><tr><td>Assistant Professor</td><td>80</td><td>52</td><td>28</td></tr><tr><td>Professor</td><td>90</td><td>59</td><td>31</td></tr></tbody></table></div><p>The masters thesis and doctoral dissertation of the applicant and relevant co-author must be attached where required.</p></div>',
        2, 80
    ),
    (
        N'modern-technologies-code',
        N'college_law_modern_technologies_code',
        N'colleges/law/scientific-affairs/modern-technologies-code',
        N'مدونة القانون لاستخدام التقنيات الحديثة',
        N'Code for the Use of Modern Technologies',
        N'عرض وتنزيل المدونة الرسمية من داخل موقع UniWeb.',
        N'View and download the official code from within UniWeb.',
        NULL, NULL,
        24, 90
    ),
    (
        N'external-contributions',
        N'college_law_external_scientific_contributions',
        N'colleges/law/scientific-affairs/contributions/external',
        N'المساهمات الخارجية',
        N'External Contributions',
        N'صفحة داخلية للمساهمات العلمية الخارجية لكلية القانون.',
        N'An internal page for the external scientific contributions of the College of Law.',
        N'<div class="law-scientific-content"><div class="alert alert-info">ورد عنصر المساهمات الخارجية في قائمة الموقع الرسمي دون رابط مستقل أو محتوى منشور يمكن نقله. تم إنشاء هذه الصفحة الداخلية لمنع الرابط المكسور، وهي مهيأة لإضافة المحتوى المعتمد من لوحة الإدارة.</div></div>',
        N'<div class="law-scientific-content"><div class="alert alert-info">The official menu listed External Contributions without an independent page or transferable published content. This internal page prevents a broken link and is ready for approved content through the administration panel.</div></div>',
        2, 100
    );

    /* ================================================================
       3) إنشاء/تحديث الصفحات والترجمات والسكشنات
       ================================================================ */
    DECLARE
        @PageKey nvarchar(100),
        @SystemName nvarchar(180),
        @Slug nvarchar(360),
        @TitleAr nvarchar(300),
        @TitleEn nvarchar(300),
        @SummaryAr nvarchar(1000),
        @SummaryEn nvarchar(1000),
        @ContentAr nvarchar(max),
        @ContentEn nvarchar(max),
        @SectionType int,
        @DisplayOrder int,
        @PageId int,
        @InternalName nvarchar(190);

    DECLARE PagesCursor CURSOR LOCAL FAST_FORWARD FOR
    SELECT PageKey, SystemName, Slug, TitleAr, TitleEn,
           SummaryAr, SummaryEn, ContentAr, ContentEn,
           SectionType, DisplayOrder
    FROM @PagesData
    ORDER BY DisplayOrder;

    OPEN PagesCursor;
    FETCH NEXT FROM PagesCursor INTO
        @PageKey, @SystemName, @Slug, @TitleAr, @TitleEn,
        @SummaryAr, @SummaryEn, @ContentAr, @ContentEn,
        @SectionType, @DisplayOrder;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        SET @PageId = NULL;
        SET @InternalName = LEFT(N'law-scientific-' + @PageKey, 190);

        SELECT TOP (1) @PageId = Id
        FROM dbo.Pages
        WHERE SystemName = @SystemName OR Slug = @Slug
        ORDER BY CASE WHEN SystemName = @SystemName THEN 0 ELSE 1 END, Id;

        IF @PageId IS NULL
        BEGIN
            INSERT dbo.Pages
            (
                SystemName, Slug, Status, LayoutType,
                IsHomePage, ShowInMenu, IsPublished, IsDeleted,
                DisplayOrder, PublishedAtUtc, CreatedAtUtc, CustomMenuId
            )
            VALUES
            (
                @SystemName, @Slug, 2, 2,
                0, 1, 1, 0,
                500 + @DisplayOrder, @Now, @Now, @MenuId
            );
            SET @PageId = CONVERT(int, SCOPE_IDENTITY());
        END
        ELSE
        BEGIN
            UPDATE dbo.Pages
            SET SystemName = @SystemName,
                Slug = @Slug,
                Status = 2,
                LayoutType = 2,
                IsHomePage = 0,
                ShowInMenu = 1,
                IsPublished = 1,
                IsDeleted = 0,
                DisplayOrder = 500 + @DisplayOrder,
                PublishedAtUtc = COALESCE(PublishedAtUtc, @Now),
                CustomMenuId = @MenuId,
                UpdatedAtUtc = @Now
            WHERE Id = @PageId;
        END;

        IF EXISTS (SELECT 1 FROM dbo.PageTranslations WHERE PageId = @PageId AND LanguageCode = N'ar')
            UPDATE dbo.PageTranslations
            SET Title = @TitleAr,
                Summary = @SummaryAr,
                Content = NULL,
                SeoTitle = @TitleAr + N' - كلية القانون - جامعة الحلة',
                SeoDescription = @SummaryAr,
                CoverImagePath = N'/uploads/colleges/law/slider/law-hero-03.webp',
                Status = 2,
                IsPublished = 1,
                PublishedAtUtc = COALESCE(PublishedAtUtc, @Now),
                UpdatedAtUtc = @Now
            WHERE PageId = @PageId AND LanguageCode = N'ar';
        ELSE
            INSERT dbo.PageTranslations
            (
                PageId, LanguageCode, Title, Summary, Content,
                SeoTitle, SeoDescription, CoverImagePath,
                Status, IsPublished, PublishedAtUtc, CreatedAtUtc
            )
            VALUES
            (
                @PageId, N'ar', @TitleAr, @SummaryAr, NULL,
                @TitleAr + N' - كلية القانون - جامعة الحلة', @SummaryAr,
                N'/uploads/colleges/law/slider/law-hero-03.webp',
                2, 1, @Now, @Now
            );

        IF EXISTS (SELECT 1 FROM dbo.PageTranslations WHERE PageId = @PageId AND LanguageCode = N'en')
            UPDATE dbo.PageTranslations
            SET Title = @TitleEn,
                Summary = @SummaryEn,
                Content = NULL,
                SeoTitle = @TitleEn + N' - College of Law - University of Hilla',
                SeoDescription = @SummaryEn,
                CoverImagePath = N'/uploads/colleges/law/slider/law-hero-03.webp',
                Status = 2,
                IsPublished = 1,
                PublishedAtUtc = COALESCE(PublishedAtUtc, @Now),
                UpdatedAtUtc = @Now
            WHERE PageId = @PageId AND LanguageCode = N'en';
        ELSE
            INSERT dbo.PageTranslations
            (
                PageId, LanguageCode, Title, Summary, Content,
                SeoTitle, SeoDescription, CoverImagePath,
                Status, IsPublished, PublishedAtUtc, CreatedAtUtc
            )
            VALUES
            (
                @PageId, N'en', @TitleEn, @SummaryEn, NULL,
                @TitleEn + N' - College of Law - University of Hilla', @SummaryEn,
                N'/uploads/colleges/law/slider/law-hero-03.webp',
                2, 1, @Now, @Now
            );

        DELETE PB
        FROM dbo.PageBlocks PB
        INNER JOIN dbo.PageSections PS ON PS.Id = PB.PageSectionId
        WHERE PS.PageId = @PageId
          AND PS.InternalName LIKE N'law-scientific-%';

        DELETE FROM dbo.PageSections
        WHERE PageId = @PageId
          AND InternalName LIKE N'law-scientific-%';

        INSERT dbo.PageSections
        (
            PageId, InternalName, SectionType,
            TitleAr, TitleEn, SubtitleAr, SubtitleEn,
            ContentAr, ContentEn,
            DocumentFolderId, DocumentFileId, PdfHeight,
            ShowDocumentTree, ShowDocumentDownloadButton,
            ColumnCount, IsFullWidth, CustomCssClass, SectionCssId,
            IsActive, IsHidden, IsDeleted, DisplayOrder, CreatedAtUtc
        )
        VALUES
        (
            @PageId, @InternalName, @SectionType,
            @TitleAr, @TitleEn, @SummaryAr, @SummaryEn,
            @ContentAr, @ContentEn,
            NULL,
            CASE WHEN @SectionType = 24 THEN @ModernTechDocumentFileId ELSE NULL END,
            950,
            0, 1,
            1, 0,
            CASE WHEN @SectionType = 24
                 THEN N'law-scientific-page law-scientific-pdf uw-college-document-panel'
                 ELSE N'law-scientific-page law-scientific-richtext uw-college-section' END,
            N'law-scientific-' + @PageKey,
            1, 0, 0, 10, @Now
        );

        FETCH NEXT FROM PagesCursor INTO
            @PageKey, @SystemName, @Slug, @TitleAr, @TitleEn,
            @SummaryAr, @SummaryEn, @ContentAr, @ContentEn,
            @SectionType, @DisplayOrder;
    END;

    CLOSE PagesCursor;
    DEALLOCATE PagesCursor;

    /* ================================================================
       4) إعادة بناء قائمة الشؤون العلمية بروابط داخلية فقط
       ================================================================ */
    SELECT TOP (1) @ScientificParentId = Id
    FROM dbo.SiteMenuItems
    WHERE SiteMenuId = @MenuId
      AND ParentId IS NULL
      AND IsDeleted = 0
      AND
      (
          TitleAr IN (N'الشؤون العلمية', N'الشؤؤن العلمية')
          OR TitleEn IN (N'Scientific Affairs', N'Academic Affairs')
      )
    ORDER BY Id;

    IF @ScientificParentId IS NULL
    BEGIN
        INSERT dbo.SiteMenuItems
        (
            SiteMenuId, ParentId, PageId,
            TitleAr, TitleEn, Url,
            OpenInNewTab, IsActive, IsDeleted,
            DisplayOrder, CreatedAtUtc
        )
        VALUES
        (
            @MenuId, NULL, NULL,
            N'الشؤون العلمية', N'Scientific Affairs', N'#',
            0, 1, 0,
            30, @Now
        );
        SET @ScientificParentId = CONVERT(int, SCOPE_IDENTITY());
    END
    ELSE
    BEGIN
        UPDATE dbo.SiteMenuItems
        SET PageId = NULL,
            TitleAr = N'الشؤون العلمية',
            TitleEn = N'Scientific Affairs',
            Url = N'#',
            OpenInNewTab = 0,
            IsActive = 1,
            IsDeleted = 0,
            DisplayOrder = 30,
            UpdatedAtUtc = @Now
        WHERE Id = @ScientificParentId;
    END;

    /* حذف أبناء الشؤون العلمية وأحفادها فقط */
    DELETE GrandChild
    FROM dbo.SiteMenuItems GrandChild
    INNER JOIN dbo.SiteMenuItems Child ON Child.Id = GrandChild.ParentId
    WHERE Child.SiteMenuId = @MenuId
      AND Child.ParentId = @ScientificParentId;

    DELETE FROM dbo.SiteMenuItems
    WHERE SiteMenuId = @MenuId
      AND ParentId = @ScientificParentId;

    DECLARE @FacultyResearchPageId int = (SELECT TOP (1) P.Id FROM dbo.Pages P WHERE P.SystemName = N'college_law_faculty_research' AND P.IsDeleted = 0);
    DECLARE @GraduationResearchPageId int = (SELECT TOP (1) P.Id FROM dbo.Pages P WHERE P.SystemName = N'college_law_graduation_research' AND P.IsDeleted = 0);
    DECLARE @ConferenceHillaPageId int = (SELECT TOP (1) P.Id FROM dbo.Pages P WHERE P.SystemName = N'college_law_ip_it_conference_hilla' AND P.IsDeleted = 0);
    DECLARE @ConferenceShirazPageId int = (SELECT TOP (1) P.Id FROM dbo.Pages P WHERE P.SystemName = N'college_law_ip_it_conference_shiraz' AND P.IsDeleted = 0);
    DECLARE @CourseDescriptionsPageId int = (SELECT TOP (1) P.Id FROM dbo.Pages P WHERE P.SystemName = N'college_law_course_descriptions' AND P.IsDeleted = 0);
    DECLARE @LecturesPageId int = (SELECT TOP (1) P.Id FROM dbo.Pages P WHERE P.SystemName = N'college_law_academic_lectures' AND P.IsDeleted = 0);
    DECLARE @ExternalContractingPageId int = (SELECT TOP (1) P.Id FROM dbo.Pages P WHERE P.SystemName = N'college_law_external_contracting_rules' AND P.IsDeleted = 0);
    DECLARE @PromotionPageId int = (SELECT TOP (1) P.Id FROM dbo.Pages P WHERE P.SystemName = N'college_law_scientific_promotion_instructions' AND P.IsDeleted = 0);
    DECLARE @ModernTechPageId int = (SELECT TOP (1) P.Id FROM dbo.Pages P WHERE P.SystemName = N'college_law_modern_technologies_code' AND P.IsDeleted = 0);
    DECLARE @ExternalContributionsPageId int = (SELECT TOP (1) P.Id FROM dbo.Pages P WHERE P.SystemName = N'college_law_external_scientific_contributions' AND P.IsDeleted = 0);

    INSERT dbo.SiteMenuItems
    (
        SiteMenuId, ParentId, PageId,
        TitleAr, TitleEn, Url,
        OpenInNewTab, IsActive, IsDeleted,
        DisplayOrder, CreatedAtUtc
    )
    VALUES
    (@MenuId, @ScientificParentId, @FacultyResearchPageId, N'بحوث التدريسيين', N'Faculty Research', NULL, 0, 1, 0, 10, @Now),
    (@MenuId, @ScientificParentId, @GraduationResearchPageId, N'بحوث التخرج', N'Graduation Research', NULL, 0, 1, 0, 20, @Now),
    (@MenuId, @ScientificParentId, NULL, N'المؤتمرات', N'Conferences', N'#', 0, 1, 0, 30, @Now);

    SET @ConferencesParentId = CONVERT(int, SCOPE_IDENTITY());

    INSERT dbo.SiteMenuItems
    (
        SiteMenuId, ParentId, PageId,
        TitleAr, TitleEn, Url,
        OpenInNewTab, IsActive, IsDeleted,
        DisplayOrder, CreatedAtUtc
    )
    VALUES
    (@MenuId, @ConferencesParentId, @ConferenceHillaPageId, N'مؤتمر حقوق الملكية الفكرية وتكنولوجيا المعلومات', N'Intellectual Property and Information Technology Conference', NULL, 0, 1, 0, 10, @Now),
    (@MenuId, @ConferencesParentId, @ConferenceShirazPageId, N'مؤتمر حقوق الملكية الفكرية وتكنولوجيا المعلومات في شيراز', N'Intellectual Property and Information Technology Conference in Shiraz', NULL, 0, 1, 0, 20, @Now);

    INSERT dbo.SiteMenuItems
    (
        SiteMenuId, ParentId, PageId,
        TitleAr, TitleEn, Url,
        OpenInNewTab, IsActive, IsDeleted,
        DisplayOrder, CreatedAtUtc
    )
    VALUES
    (@MenuId, @ScientificParentId, @CourseDescriptionsPageId, N'وصف المقررات الدراسية', N'Course Descriptions', NULL, 0, 1, 0, 40, @Now),
    (@MenuId, @ScientificParentId, @LecturesPageId, N'المحاضرات الدراسية', N'Academic Lectures', NULL, 0, 1, 0, 50, @Now),
    (@MenuId, @ScientificParentId, @ExternalContractingPageId, N'ضوابط التعاقد مع جهات خارجية', N'Rules for Contracting with External Entities', NULL, 0, 1, 0, 60, @Now),
    (@MenuId, @ScientificParentId, @PromotionPageId, N'تعليمات الترقية العلمية', N'Scientific Promotion Instructions', NULL, 0, 1, 0, 70, @Now),
    (@MenuId, @ScientificParentId, @ModernTechPageId, N'مدونة القانون لاستخدام التقنيات الحديثة', N'Code for the Use of Modern Technologies', NULL, 0, 1, 0, 80, @Now),
    (@MenuId, @ScientificParentId, NULL, N'المساهمات', N'Contributions', N'#', 0, 1, 0, 90, @Now);

    SET @ContributionsParentId = CONVERT(int, SCOPE_IDENTITY());

    INSERT dbo.SiteMenuItems
    (
        SiteMenuId, ParentId, PageId,
        TitleAr, TitleEn, Url,
        OpenInNewTab, IsActive, IsDeleted,
        DisplayOrder, CreatedAtUtc
    )
    VALUES
    (@MenuId, @ContributionsParentId, @ExternalContributionsPageId, N'مساهمات خارجية', N'External Contributions', NULL, 0, 1, 0, 10, @Now);

    IF EXISTS
    (
        SELECT 1
        FROM dbo.SiteMenuItems M
        WHERE M.SiteMenuId = @MenuId
          AND
          (
              M.Id = @ScientificParentId
              OR M.ParentId = @ScientificParentId
              OR M.ParentId IN
                 (
                     SELECT Id FROM dbo.SiteMenuItems
                     WHERE SiteMenuId = @MenuId AND ParentId = @ScientificParentId
                 )
          )
          AND M.Url LIKE N'%law.hilla-unc.edu.iq%'
    )
        THROW 52603, N'بقي رابط خارجي قديم داخل قائمة الشؤون العلمية.', 1;

    IF NOT EXISTS
    (
        SELECT 1
        FROM dbo.PageSections PS
        INNER JOIN dbo.Pages P ON P.Id = PS.PageId
        WHERE P.SystemName = N'college_law_modern_technologies_code'
          AND P.IsDeleted = 0
          AND PS.IsDeleted = 0
          AND PS.SectionType = 24
          AND PS.DocumentFolderId IS NULL
          AND PS.DocumentFileId = @ModernTechDocumentFileId
    )
        THROW 52604, N'لم يتم ربط ملف مدونة التقنيات الحديثة بعارض PDF بصورة صحيحة.', 1;

    COMMIT TRANSACTION;

    SELECT
        @CollegeId AS CollegeId,
        @MenuId AS MenuId,
        @ScientificParentId AS ScientificAffairsMenuItemId,
        @DocumentFolderId AS ScientificDocumentFolderId,
        @ModernTechDocumentFileId AS ModernTechnologiesDocumentFileId,
        (SELECT COUNT(*) FROM @PagesData) AS InternalPagesPrepared,
        (SELECT COUNT(*) FROM dbo.SiteMenuItems WHERE SiteMenuId = @MenuId AND ParentId = @ScientificParentId) AS ScientificAffairsDirectItems,
        N'تم إنشاء صفحات الشؤون العلمية الداخلية وربط القائمة وملف PDF المحلي بنجاح.' AS ResultMessage;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION;
    THROW;
END CATCH;
