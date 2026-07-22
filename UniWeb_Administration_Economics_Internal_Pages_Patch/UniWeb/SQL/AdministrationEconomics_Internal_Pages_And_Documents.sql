/*
    UniWeb - College of Administration and Economics
    Internal CMS pages, nested internal menu, and locally stored documents

    التنفيذ من SQL Server Management Studio (SSMS)

    هذا السكربت:
    - ينشئ صفحات "عن الكلية" داخلياً بالعربية والإنكليزية.
    - يربط القائمة بواسطة PageId ولا يترك روابط خارجية داخل فرع "عن الكلية".
    - يسجل الخطة الاستراتيجية وتقرير التقييم الذاتي في DocumentFiles.
    - لا يعدل Models أو Controllers أو Routes ولا يستخدم Migration أو Seeder.
    - لا يغير عناصر القوائم الواقعة خارج فرع "عن الكلية".
*/
SET NOCOUNT ON;
SET XACT_ABORT ON;

BEGIN TRY
    BEGIN TRANSACTION;

    DECLARE @Now datetime2(7) = SYSUTCDATETIME();
    DECLARE @CollegeId int, @MenuId int, @DocumentFolderId int;

    IF OBJECT_ID(N'dbo.Pages', N'U') IS NULL
       OR OBJECT_ID(N'dbo.PageTranslations', N'U') IS NULL
       OR OBJECT_ID(N'dbo.PageSections', N'U') IS NULL
       OR OBJECT_ID(N'dbo.PageBlocks', N'U') IS NULL
       OR OBJECT_ID(N'dbo.SiteMenus', N'U') IS NULL
       OR OBJECT_ID(N'dbo.SiteMenuItems', N'U') IS NULL
       OR OBJECT_ID(N'dbo.AcademicColleges', N'U') IS NULL
       OR OBJECT_ID(N'dbo.DocumentFolders', N'U') IS NULL
       OR OBJECT_ID(N'dbo.DocumentFiles', N'U') IS NULL
        THROW 53000, N'قاعدة البيانات لا تحتوي جداول UniWeb المطلوبة.', 1;

    SELECT TOP (1) @CollegeId = Id
    FROM dbo.AcademicColleges
    WHERE IsActive = 1
      AND
      (
          Slug = N'colleges/administration-economics'
          OR Code IN (N'ADMECON', N'ADMIN-ECON', N'AE', N'ACCOUNT')
          OR NameAr LIKE N'%الإدارة والاقتصاد%'
          OR NameAr LIKE N'%الادارة والاقتصاد%'
          OR NameEn LIKE N'%Administration%Economics%'
      )
    ORDER BY CASE WHEN Slug = N'colleges/administration-economics' THEN 0 ELSE 1 END, Id;

    IF @CollegeId IS NULL
        THROW 53001, N'لم يتم العثور على سجل كلية الإدارة والاقتصاد. نفّذ سكربت الصفحة الرئيسية أولاً.', 1;

    SELECT @MenuId = CustomMenuId
    FROM dbo.AcademicColleges
    WHERE Id = @CollegeId;

    IF @MenuId IS NULL
    BEGIN
        SELECT TOP (1) @MenuId = Id
        FROM dbo.SiteMenus
        WHERE IsDeleted = 0
          AND SystemName IN
          (
              N'college-administration-economics-menu',
              N'administration-economics-menu',
              N'college-account-menu'
          )
        ORDER BY Id;
    END

    IF @MenuId IS NULL
        THROW 53002, N'لم يتم العثور على القائمة الخاصة بكلية الإدارة والاقتصاد.', 1;

    /* 1) مجلد المستندات */
    SELECT TOP (1) @DocumentFolderId = Id
    FROM dbo.DocumentFolders
    WHERE IsDeleted = 0
      AND AcademicCollegeId = @CollegeId
      AND Slug = N'administration-economics-governance-documents';

    IF @DocumentFolderId IS NULL
    BEGIN
        INSERT dbo.DocumentFolders
        (
            ParentId, NameAr, NameEn, Slug,
            DescriptionAr, DescriptionEn, IconClass,
            IsActive, IsDeleted, DisplayOrder, AcademicCollegeId, CreatedAtUtc
        )
        VALUES
        (
            NULL,
            N'الخطط والجودة والاعتماد - كلية الإدارة والاقتصاد',
            N'Plans, Quality and Accreditation - College of Administration and Economics',
            N'administration-economics-governance-documents',
            N'الخطة الاستراتيجية ووثائق الجودة والتقييم والاعتماد الخاصة بالكلية والمحفوظة محلياً داخل UniWeb.',
            N'Strategic planning, quality, evaluation, and accreditation documents stored locally in UniWeb.',
            N'bi bi-folder2-open',
            1, 0, 15, @CollegeId, @Now
        );
        SET @DocumentFolderId = CONVERT(int, SCOPE_IDENTITY());
    END
    ELSE
    BEGIN
        UPDATE dbo.DocumentFolders
        SET NameAr = N'الخطط والجودة والاعتماد - كلية الإدارة والاقتصاد',
            NameEn = N'Plans, Quality and Accreditation - College of Administration and Economics',
            DescriptionAr = N'الخطة الاستراتيجية ووثائق الجودة والتقييم والاعتماد الخاصة بالكلية والمحفوظة محلياً داخل UniWeb.',
            DescriptionEn = N'Strategic planning, quality, evaluation, and accreditation documents stored locally in UniWeb.',
            IconClass = N'bi bi-folder2-open',
            IsActive = 1,
            IsDeleted = 0,
            AcademicCollegeId = @CollegeId,
            UpdatedAtUtc = @Now
        WHERE Id = @DocumentFolderId;
    END

    DECLARE @LocalDocuments TABLE
    (
        DocumentKey nvarchar(80) NOT NULL PRIMARY KEY,
        FilePath nvarchar(600) NOT NULL,
        FileName nvarchar(260) NOT NULL,
        TitleAr nvarchar(300) NOT NULL,
        TitleEn nvarchar(300) NOT NULL,
        DescriptionAr nvarchar(max) NULL,
        DescriptionEn nvarchar(max) NULL,
        DisplayOrder int NOT NULL
    );

    INSERT @LocalDocuments
    (
        DocumentKey, FilePath, FileName,
        TitleAr, TitleEn, DescriptionAr, DescriptionEn, DisplayOrder
    )
    VALUES
    (
        N'strategic-plan',
        N'/uploads/colleges/administration-economics/documents/administration-economics-strategic-plan-2024-2029.pdf',
        N'administration-economics-strategic-plan-2024-2029.pdf',
        N'الخطة الاستراتيجية لكلية الإدارة والاقتصاد 2024-2029',
        N'College of Administration and Economics Strategic Plan 2024-2029',
        N'الخطة الاستراتيجية الرسمية محفوظة محلياً داخل UniWeb.',
        N'The official strategic plan stored locally in UniWeb.',
        10
    ),
    (
        N'self-evaluation-report',
        N'/uploads/colleges/administration-economics/documents/administration-economics-self-evaluation-report.pdf',
        N'administration-economics-self-evaluation-report.pdf',
        N'تقرير التقييم الذاتي لكلية الإدارة والاقتصاد',
        N'College of Administration and Economics Self-Evaluation Report',
        N'تقرير التقييم الذاتي الرسمي محفوظ محلياً داخل نظام المستندات.',
        N'The official self-evaluation report stored locally in the document system.',
        20
    );

    UPDATE D
    SET D.DocumentFolderId = @DocumentFolderId,
        D.AcademicCollegeId = @CollegeId,
        D.TitleAr = S.TitleAr,
        D.TitleEn = S.TitleEn,
        D.DescriptionAr = S.DescriptionAr,
        D.DescriptionEn = S.DescriptionEn,
        D.OriginalFileName = S.FileName,
        D.StoredFileName = S.FileName,
        D.Extension = N'.pdf',
        D.ContentType = N'application/pdf',
        D.IsPdf = 1,
        D.IsFeatured = 1,
        D.IsActive = 1,
        D.IsDeleted = 0,
        D.DisplayOrder = S.DisplayOrder,
        D.UpdatedAtUtc = @Now
    FROM dbo.DocumentFiles D
    INNER JOIN @LocalDocuments S ON S.FilePath = D.FilePath;

    INSERT dbo.DocumentFiles
    (
        DocumentFolderId, AcademicCollegeId,
        TitleAr, TitleEn, DescriptionAr, DescriptionEn,
        OriginalFileName, StoredFileName, FilePath,
        Extension, ContentType, FileSizeBytes,
        IsPdf, IsFeatured, IsActive, IsDeleted,
        DisplayOrder, CreatedAtUtc
    )
    SELECT
        @DocumentFolderId, @CollegeId,
        S.TitleAr, S.TitleEn, S.DescriptionAr, S.DescriptionEn,
        S.FileName, S.FileName, S.FilePath,
        N'.pdf', N'application/pdf', 0,
        1, 1, 1, 0,
        S.DisplayOrder, @Now
    FROM @LocalDocuments S
    WHERE NOT EXISTS
    (
        SELECT 1 FROM dbo.DocumentFiles D WHERE D.FilePath = S.FilePath
    );

    /* 2) تعريف الصفحات الداخلية: 2 = RichText, 24 = PdfViewer */
    DECLARE @InternalPages TABLE
    (
        PageKey nvarchar(80) NOT NULL PRIMARY KEY,
        SystemName nvarchar(150) NOT NULL,
        Slug nvarchar(300) NOT NULL,
        TitleAr nvarchar(300) NOT NULL,
        TitleEn nvarchar(300) NOT NULL,
        SummaryAr nvarchar(1000) NULL,
        SummaryEn nvarchar(1000) NULL,
        ContentAr nvarchar(max) NULL,
        ContentEn nvarchar(max) NULL,
        SectionType int NOT NULL,
        DocumentKey nvarchar(80) NULL,
        DisplayOrder int NOT NULL
    );

    INSERT @InternalPages
    (
        PageKey, SystemName, Slug,
        TitleAr, TitleEn, SummaryAr, SummaryEn,
        ContentAr, ContentEn, SectionType, DocumentKey, DisplayOrder
    )
    VALUES
    (
        N'dean-message', N'college_administration_economics_dean_message',
        N'colleges/administration-economics/about/dean-message',
        N'كلمة السيد العميد', N'Dean''s Message',
        N'كلمة عمادة الكلية بشأن التعليم والبحث العلمي وخدمة المجتمع.',
        N'A message from the College leadership on education, research, and community service.',
        N'<div class="uw-college-rich-content"><p class="lead"><strong>الدكتور حسين ديكان درويش</strong><br>عميد كلية الإدارة والاقتصاد</p><p>نرحب بطلبتنا وأعضاء الهيئة التدريسية والضيوف في كلية الإدارة والاقتصاد، التي تسعى إلى تقديم تعليم أكاديمي نوعي وإعداد خريجين يمتلكون المعرفة والمهارات اللازمة للنجاح في مجالات الإدارة والمحاسبة والاقتصاد.</p><p>تؤمن الكلية بأن الاستثمار في العلم والمعرفة هو أساس بناء المستقبل، ولذلك تعمل على تطوير المناهج وتشجيع الابتكار والبحث العلمي وتوفير بيئة تعليمية محفزة تستجيب لمتطلبات سوق العمل.</p><p>كما تحرص العمادة على بناء شراكات أكاديمية واقتصادية فاعلة، وتعزيز خدمة المجتمع، وترسيخ الجودة والنزاهة والمسؤولية المهنية.</p></div>',
        N'<div class="uw-college-rich-content"><p class="lead"><strong>Dr Hussein Dikan Darwish</strong><br>Dean of the College of Administration and Economics</p><p>The College seeks to provide high-quality academic education and prepare graduates with the knowledge and skills required for administration, accounting, and economics.</p><p>It develops curricula, supports innovation and research, and provides a motivating learning environment responsive to labour-market needs.</p><p>The Deanship also builds academic and economic partnerships, serves the community, and promotes quality, integrity, and professional responsibility.</p></div>',
        2, NULL, 10
    ),
    (
        N'vision-mission-goals', N'college_administration_economics_vision_mission_goals',
        N'colleges/administration-economics/about/vision-mission-goals',
        N'الرؤية والرسالة والأهداف', N'Vision, Mission and Goals',
        N'المرتكزات الأكاديمية والمهنية للكلية.',
        N'The academic and professional foundations of the College.',
        N'<div class="uw-college-rich-content"><h3>الرؤية</h3><p>أن تكون كلية الإدارة والاقتصاد رائدة في تقديم تعليم متميز في مجالي المحاسبة والاقتصاد، لإعداد قادة إداريين وخبراء اقتصاديين ذوي كفاءة عالية يساهمون في تعزيز التطور الاقتصادي والمالي المستدام.</p><h3>الرسالة</h3><p>تقديم برامج أكاديمية متطورة في مجالي المحاسبة والاقتصاد لتأهيل خريجين يمتلكون المعرفة النظرية والمهارات العملية اللازمة للتميز في الأعمال والإدارة المالية والتخطيط الاقتصادي، مع التركيز على الابتكار والتنمية المستدامة وخدمة المجتمع.</p><h3>الأهداف</h3><ol><li>تطوير برامج أكاديمية تواكب احتياجات سوق العمل.</li><li>تنمية المهارات القيادية والإدارية والتحليلية.</li><li>دعم البحث العلمي في المحاسبة والاقتصاد واستراتيجيات الأعمال.</li><li>تعزيز الشراكات المهنية والتدريب الميداني.</li><li>تشجيع الابتكار والمسؤولية المجتمعية والتنمية المستدامة.</li></ol></div>',
        N'<div class="uw-college-rich-content"><h3>Vision</h3><p>To lead in distinguished accounting and economics education and prepare highly competent administrative leaders and economic experts who contribute to sustainable economic and financial development.</p><h3>Mission</h3><p>To provide advanced accounting and economics programmes that prepare graduates with theoretical knowledge and practical skills for business, financial management, and economic planning, while promoting innovation, sustainable development, and community service.</p><h3>Goals</h3><ol><li>Develop programmes responsive to labour-market needs.</li><li>Develop leadership, administrative, and analytical skills.</li><li>Support research in accounting, economics, and business strategy.</li><li>Strengthen partnerships and field training.</li><li>Promote innovation, social responsibility, and sustainable development.</li></ol></div>',
        2, NULL, 20
    ),
    (
        N'strategic-plan', N'college_administration_economics_strategic_plan',
        N'colleges/administration-economics/about/strategic-plan',
        N'الخطة الاستراتيجية', N'Strategic Plan',
        N'عرض وتنزيل الخطة الاستراتيجية من داخل UniWeb.',
        N'View and download the strategic plan from within UniWeb.',
        NULL, NULL, 24, N'strategic-plan', 30
    ),
    (
        N'organizational-structure', N'college_administration_economics_organizational_structure',
        N'colleges/administration-economics/about/organizational-structure',
        N'الهيكل التنظيمي', N'Organizational Structure',
        N'البنية الأكاديمية والإدارية للكلية.',
        N'The College academic and administrative structure.',
        N'<div class="uw-college-rich-content"><div class="row g-3 text-center"><div class="col-12"><div class="p-4 border rounded-4 bg-light"><strong>مجلس الكلية</strong><div class="text-muted mt-2">الجهة الأكاديمية والإدارية العليا</div></div></div><div class="col-12"><div class="p-4 border rounded-4"><strong>عمادة كلية الإدارة والاقتصاد</strong><div class="text-muted mt-2">القيادة الأكاديمية والإدارة والمتابعة</div></div></div><div class="col-md-4"><div class="p-4 border rounded-4 h-100"><strong>قسم المحاسبة</strong><div class="text-muted mt-2">التعليم والبحث والبرنامج الأكاديمي</div></div></div><div class="col-md-4"><div class="p-4 border rounded-4 h-100"><strong>الشعب والوحدات العلمية</strong><div class="text-muted mt-2">الجودة والتعليم المستمر والأنشطة والبحث العلمي</div></div></div><div class="col-md-4"><div class="p-4 border rounded-4 h-100"><strong>الشعب والوحدات الإدارية</strong><div class="text-muted mt-2">شؤون الطلبة والخدمات والدعم المؤسسي</div></div></div></div><p class="text-muted mt-4">يمكن تحديث التفاصيل من لوحة المحتوى عند اعتماد نسخة تنظيمية أحدث.</p></div>',
        N'<div class="uw-college-rich-content"><div class="row g-3 text-center"><div class="col-12"><div class="p-4 border rounded-4 bg-light"><strong>College Council</strong><div class="text-muted mt-2">The highest academic and administrative body</div></div></div><div class="col-12"><div class="p-4 border rounded-4"><strong>College Deanship</strong><div class="text-muted mt-2">Academic leadership and administration</div></div></div><div class="col-md-4"><div class="p-4 border rounded-4 h-100"><strong>Department of Accounting</strong><div class="text-muted mt-2">Teaching, research, and programme delivery</div></div></div><div class="col-md-4"><div class="p-4 border rounded-4 h-100"><strong>Academic Units</strong><div class="text-muted mt-2">Quality, continuing education, activities, and research</div></div></div><div class="col-md-4"><div class="p-4 border rounded-4 h-100"><strong>Administrative Units</strong><div class="text-muted mt-2">Student affairs, services, and institutional support</div></div></div></div><p class="text-muted mt-4">Details can be updated through the CMS when a newer approved structure is issued.</p></div>',
        2, NULL, 40
    ),
    (
        N'course-descriptions', N'college_administration_economics_course_descriptions',
        N'colleges/administration-economics/about/course-descriptions',
        N'وصف المقررات', N'Course Descriptions',
        N'محاور المقررات العلمية والعملية في برنامج المحاسبة.',
        N'Academic and practical course areas in the Accounting programme.',
        N'<div class="uw-college-rich-content"><p>تغطي مقررات قسم المحاسبة المعارف والمهارات المطلوبة في البيئة المالية والإدارية الحديثة.</p><div class="row g-3"><div class="col-md-6"><div class="p-4 border rounded-4 h-100"><h4>المحاسبة الأساسية والمالية</h4><p>المبادئ المحاسبية وإعداد القوائم وتحليل العمليات.</p></div></div><div class="col-md-6"><div class="p-4 border rounded-4 h-100"><h4>المحاسبة الإدارية والتكاليف</h4><p>قياس التكاليف والتخطيط والرقابة ودعم القرار.</p></div></div><div class="col-md-6"><div class="p-4 border rounded-4 h-100"><h4>التدقيق والضرائب</h4><p>أسس التدقيق والرقابة والتشريعات الضريبية.</p></div></div><div class="col-md-6"><div class="p-4 border rounded-4 h-100"><h4>نظم المعلومات والتحليل المالي</h4><p>النظم المحاسبية الرقمية وتحليل القوائم والمؤشرات.</p></div></div></div><p class="text-muted mt-4">يمكن إضافة ملفات الوصف التفصيلية المعتمدة إلى مكتبة المستندات عند نشرها رسمياً.</p></div>',
        N'<div class="uw-college-rich-content"><p>The Accounting courses cover the knowledge and skills required in modern financial and administrative environments.</p><div class="row g-3"><div class="col-md-6"><div class="p-4 border rounded-4 h-100"><h4>Basic and Financial Accounting</h4><p>Accounting principles, statements, and transaction analysis.</p></div></div><div class="col-md-6"><div class="p-4 border rounded-4 h-100"><h4>Managerial and Cost Accounting</h4><p>Cost measurement, planning, control, and decision support.</p></div></div><div class="col-md-6"><div class="p-4 border rounded-4 h-100"><h4>Auditing and Taxation</h4><p>Auditing, control, and tax legislation.</p></div></div><div class="col-md-6"><div class="p-4 border rounded-4 h-100"><h4>Information Systems and Financial Analysis</h4><p>Digital accounting systems and financial indicator analysis.</p></div></div></div><p class="text-muted mt-4">Approved detailed files can be added to the document library when officially published.</p></div>',
        2, NULL, 50
    ),
    (
        N'academic-program', N'college_administration_economics_academic_program',
        N'colleges/administration-economics/about/academic-program-description',
        N'وصف البرنامج الأكاديمي', N'Academic Programme Description',
        N'وصف برنامج المحاسبة ومخرجاته ومجالات عمل الخريجين.',
        N'An overview of the Accounting programme, outcomes, and graduate careers.',
        N'<div class="uw-college-rich-content"><h3>برنامج المحاسبة</h3><p>يدرس البرنامج الأنظمة المالية والمحاسبية ويؤهل الطلبة لفهم العمليات وتحليل البيانات وإعداد القوائم المالية ومراجعتها ضمن الأطر المهنية والقانونية.</p><h3>المعارف والمهارات</h3><ul><li>تطبيق المبادئ والمعايير المحاسبية.</li><li>تحليل القوائم والمؤشرات ودعم القرار.</li><li>استخدام نظم المعلومات والتطبيقات الرقمية.</li><li>فهم التدقيق والرقابة والتكاليف والضرائب.</li><li>الالتزام بالنزاهة وأخلاقيات المهنة.</li></ul><h3>مجالات العمل</h3><p>المصارف ومكاتب التدقيق والمؤسسات الحكومية والشركات والمحاسبة القانونية والاستشارات المالية.</p></div>',
        N'<div class="uw-college-rich-content"><h3>Accounting Programme</h3><p>The programme studies financial and accounting systems and prepares students to analyse data and prepare and review financial statements within professional and legal frameworks.</p><h3>Knowledge and Skills</h3><ul><li>Apply accounting principles and standards.</li><li>Analyse financial statements and indicators.</li><li>Use accounting information systems.</li><li>Understand auditing, control, costing, and taxation.</li><li>Follow integrity and professional ethics.</li></ul><h3>Careers</h3><p>Banks, audit firms, government institutions, companies, legal accounting, and financial consulting.</p></div>',
        2, NULL, 60
    ),
    (
        N'quality-policy', N'college_administration_economics_quality_policy',
        N'colleges/administration-economics/about/quality-policy',
        N'سياسة الجودة', N'Quality Policy',
        N'التزام الكلية بالجودة والتحسين المستمر.',
        N'The College commitment to quality and continuous improvement.',
        N'<div class="uw-college-rich-content"><p>تلتزم الكلية بنظام جودة يدعم رسالتها ويرفع كفاءة مخرجاتها.</p><ol><li>تقديم تعليم عالي الجودة ينسجم مع المعايير وسوق العمل.</li><li>تحديث البرامج والمناهج دورياً.</li><li>تنمية قدرات التدريسيين والكوادر.</li><li>دعم البحث المرتبط بالقضايا الاقتصادية والمالية.</li><li>تعزيز التفاعل مع المجتمع وأصحاب العلاقة.</li><li>قياس رضا الطلبة وتحسين تجربة التعلم.</li><li>تطبيق إجراءات كفوءة وشفافة.</li><li>التقييم الدوري واستخدام النتائج في التحسين.</li></ol></div>',
        N'<div class="uw-college-rich-content"><p>The College applies a quality system that supports its mission and improves outcomes.</p><ol><li>Provide high-quality education aligned with standards and labour-market needs.</li><li>Update programmes and curricula periodically.</li><li>Develop faculty and administrative staff.</li><li>Support research connected to economic and financial issues.</li><li>Engage the community and stakeholders.</li><li>Measure student satisfaction and improve learning.</li><li>Apply efficient and transparent procedures.</li><li>Evaluate performance and use results for improvement.</li></ol></div>',
        2, NULL, 70
    ),
    (
        N'accreditation', N'college_administration_economics_academic_accreditation',
        N'colleges/administration-economics/about/academic-accreditation',
        N'الاعتماد الأكاديمي', N'Academic Accreditation',
        N'بوابة داخلية لوثائق الجودة والاعتماد والتقييم.',
        N'An internal gateway to quality, accreditation, and evaluation resources.',
        N'<div class="uw-college-rich-content"><p>تجمع هذه الصفحة الموارد المنشورة ذات الصلة بالجودة والاعتماد والتحسين المستمر.</p><div class="row g-3"><div class="col-md-6"><a class="d-block p-4 border rounded-4 text-decoration-none h-100" href="/ar/pages/colleges/administration-economics/about/quality-policy"><strong>سياسة الجودة</strong><span class="d-block text-muted mt-2">مرتكزات الجودة والتحسين.</span></a></div><div class="col-md-6"><a class="d-block p-4 border rounded-4 text-decoration-none h-100" href="/ar/pages/colleges/administration-economics/about/academic-program-description"><strong>وصف البرنامج الأكاديمي</strong><span class="d-block text-muted mt-2">الأهداف والمخرجات.</span></a></div><div class="col-md-6"><a class="d-block p-4 border rounded-4 text-decoration-none h-100" href="/ar/pages/colleges/administration-economics/about/strategic-plan"><strong>الخطة الاستراتيجية</strong><span class="d-block text-muted mt-2">الوثيقة الرسمية المحلية.</span></a></div><div class="col-md-6"><a class="d-block p-4 border rounded-4 text-decoration-none h-100" href="/ar/pages/colleges/administration-economics/about/academic-accreditation/self-evaluation-report"><strong>تقرير التقييم الذاتي</strong><span class="d-block text-muted mt-2">عرض التقرير.</span></a></div></div></div>',
        N'<div class="uw-college-rich-content"><p>This page brings together published quality, accreditation, and continuous-improvement resources.</p><div class="row g-3"><div class="col-md-6"><a class="d-block p-4 border rounded-4 text-decoration-none h-100" href="/en/pages/colleges/administration-economics/about/quality-policy"><strong>Quality Policy</strong><span class="d-block text-muted mt-2">Quality and improvement foundations.</span></a></div><div class="col-md-6"><a class="d-block p-4 border rounded-4 text-decoration-none h-100" href="/en/pages/colleges/administration-economics/about/academic-program-description"><strong>Academic Programme</strong><span class="d-block text-muted mt-2">Goals and outcomes.</span></a></div><div class="col-md-6"><a class="d-block p-4 border rounded-4 text-decoration-none h-100" href="/en/pages/colleges/administration-economics/about/strategic-plan"><strong>Strategic Plan</strong><span class="d-block text-muted mt-2">The local official document.</span></a></div><div class="col-md-6"><a class="d-block p-4 border rounded-4 text-decoration-none h-100" href="/en/pages/colleges/administration-economics/about/academic-accreditation/self-evaluation-report"><strong>Self-Evaluation Report</strong><span class="d-block text-muted mt-2">View the report.</span></a></div></div></div>',
        2, NULL, 80
    ),
    (
        N'accreditation-updates', N'college_administration_economics_accreditation_updates',
        N'colleges/administration-economics/about/academic-accreditation/updates',
        N'مستجدات الاعتماد الأكاديمي', N'Academic Accreditation Updates',
        N'صفحة داخلية لنشر مستجدات الاعتماد الأكاديمي.',
        N'An internal page for academic accreditation updates.',
        N'<div class="uw-college-rich-content"><div class="alert alert-info rounded-4"><strong>صفحة مهيأة للنشر</strong><p class="mb-0 mt-2">لم يتضمن المصدر الرسمي المرسل مواد مستقلة موثقة بهذا العنوان. تم تجهيز الصفحة لتحديثها من لوحة الإدارة عند نشر الأخبار والقرارات الرسمية، من دون إضافة أرقام اعتماد غير موثقة.</p></div></div>',
        N'<div class="uw-college-rich-content"><div class="alert alert-info rounded-4"><strong>Publishing-ready page</strong><p class="mb-0 mt-2">The supplied official source did not contain independently verified material under this title. The page is ready for official updates through the administration panel; no unverified accreditation claims were added.</p></div></div>',
        2, NULL, 90
    ),
    (
        N'accreditation-agenda', N'college_administration_economics_accreditation_agenda',
        N'colleges/administration-economics/about/academic-accreditation/agenda',
        N'أجندة الاعتماد الأكاديمي', N'Academic Accreditation Agenda',
        N'صفحة داخلية لنشر أجندة الاعتماد.',
        N'An internal page for the accreditation agenda.',
        N'<div class="uw-college-rich-content"><div class="alert alert-secondary rounded-4"><strong>أجندة قابلة للتحديث</strong><p class="mb-0 mt-2">لم تُنشر أجندة زمنية مستقلة موثقة في الروابط المرسلة. يمكن إضافة المواعيد واللجان والمهام من لوحة الإدارة بعد اعتمادها، من دون اختلاق تواريخ غير منشورة.</p></div></div>',
        N'<div class="uw-college-rich-content"><div class="alert alert-secondary rounded-4"><strong>Updateable agenda</strong><p class="mb-0 mt-2">No independently verified timetable was published in the supplied links. Approved dates, committees, and tasks can be added through the administration panel without inventing unpublished deadlines.</p></div></div>',
        2, NULL, 100
    ),
    (
        N'self-evaluation-report', N'college_administration_economics_self_evaluation_report',
        N'colleges/administration-economics/about/academic-accreditation/self-evaluation-report',
        N'تقرير التقييم الذاتي', N'Self-Evaluation Report',
        N'عرض وتنزيل تقرير التقييم الذاتي من داخل UniWeb.',
        N'View and download the self-evaluation report from within UniWeb.',
        NULL, NULL, 24, N'self-evaluation-report', 110
    ),
    (
        N'college-council', N'college_administration_economics_college_council',
        N'colleges/administration-economics/about/college-council',
        N'مجلس الكلية', N'College Council',
        N'اختصاصات مجلس الكلية وآلية تحديث بيانات أعضائه.',
        N'College Council responsibilities and member-data maintenance.',
        N'<div class="uw-college-rich-content"><p>مجلس الكلية هو الجهة الأكاديمية والإدارية العليا، ويناقش الخطط والبرامج والشؤون العلمية والطلابية والإدارية وفق التعليمات النافذة.</p><h3>المهام الرئيسة</h3><ul><li>مراجعة الخطط والمناهج ومقترحات التطوير.</li><li>متابعة الجودة ومخرجات التعلم والبحث العلمي.</li><li>مناقشة شؤون الطلبة والتدريسيين واللجان.</li><li>دعم الشراكات وخدمة المجتمع والتدريب.</li><li>متابعة تنفيذ القرارات والتوصيات.</li></ul><div class="alert alert-light border rounded-4">تُحدّث أسماء الأعضاء وصفاتهم من لوحة المحتوى عند اعتماد قائمة رسمية محدثة؛ لم تضف الحزمة أسماء غير موثقة.</div></div>',
        N'<div class="uw-college-rich-content"><p>The College Council is the highest academic and administrative body and discusses programmes, scientific affairs, student matters, and administration under applicable regulations.</p><h3>Core Responsibilities</h3><ul><li>Review plans, curricula, and development proposals.</li><li>Follow up quality, outcomes, and research.</li><li>Discuss student, faculty, and committee matters.</li><li>Support partnerships, community service, and training.</li><li>Follow up approved decisions.</li></ul><div class="alert alert-light border rounded-4">Member names and roles can be updated through the CMS after an updated official list is approved; no unverified names were added.</div></div>',
        2, NULL, 120
    ),
    (
        N'contact', N'college_administration_economics_contact',
        N'colleges/administration-economics/about/contact',
        N'تواصل مع الكلية', N'Contact the College',
        N'بيانات الاتصال والموقع الرسمي للكلية.',
        N'Official College contact and location details.',
        N'<div class="uw-college-rich-content"><div class="row g-3"><div class="col-md-6"><div class="p-4 border rounded-4 h-100"><h4>العنوان</h4><p class="mb-0">العراق - بابل - الحلة، طريق الحلة - النجف، جامعة الحلة.</p></div></div><div class="col-md-6"><div class="p-4 border rounded-4 h-100"><h4>البريد الإلكتروني</h4><p class="mb-0"><a href="mailto:Management_and_Economics@hilla-unc.edu.iq">Management_and_Economics@hilla-unc.edu.iq</a></p></div></div></div></div>',
        N'<div class="uw-college-rich-content"><div class="row g-3"><div class="col-md-6"><div class="p-4 border rounded-4 h-100"><h4>Address</h4><p class="mb-0">University of Hilla, Hilla-Najaf Road, Babylon, Iraq.</p></div></div><div class="col-md-6"><div class="p-4 border rounded-4 h-100"><h4>Email</h4><p class="mb-0"><a href="mailto:Management_and_Economics@hilla-unc.edu.iq">Management_and_Economics@hilla-unc.edu.iq</a></p></div></div></div></div>',
        2, NULL, 130
    );

    /* 3) إنشاء أو تحديث الصفحات والترجمات والسكشنات */
    DECLARE
        @PageKey nvarchar(80), @SystemName nvarchar(150), @Slug nvarchar(300),
        @TitleAr nvarchar(300), @TitleEn nvarchar(300),
        @SummaryAr nvarchar(1000), @SummaryEn nvarchar(1000),
        @ContentAr nvarchar(max), @ContentEn nvarchar(max),
        @SectionType int, @DocumentKey nvarchar(80), @DisplayOrder int,
        @PageId int, @DocumentFileId int, @InternalName nvarchar(150);

    DECLARE PageCursor CURSOR LOCAL FAST_FORWARD FOR
    SELECT PageKey, SystemName, Slug, TitleAr, TitleEn, SummaryAr, SummaryEn,
           ContentAr, ContentEn, SectionType, DocumentKey, DisplayOrder
    FROM @InternalPages
    ORDER BY DisplayOrder;

    OPEN PageCursor;
    FETCH NEXT FROM PageCursor INTO @PageKey, @SystemName, @Slug, @TitleAr, @TitleEn,
        @SummaryAr, @SummaryEn, @ContentAr, @ContentEn, @SectionType, @DocumentKey, @DisplayOrder;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        SET @PageId = NULL;
        SET @DocumentFileId = NULL;
        SET @InternalName = LEFT(N'admeco-internal-' + @PageKey, 150);

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
                300 + @DisplayOrder, @Now, @Now, @MenuId
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
                DisplayOrder = 300 + @DisplayOrder,
                PublishedAtUtc = COALESCE(PublishedAtUtc, @Now),
                CustomMenuId = @MenuId,
                UpdatedAtUtc = @Now
            WHERE Id = @PageId;
        END

        IF EXISTS (SELECT 1 FROM dbo.PageTranslations WHERE PageId = @PageId AND LanguageCode = N'ar')
            UPDATE dbo.PageTranslations
            SET Title = @TitleAr, Summary = @SummaryAr, Content = NULL,
                SeoTitle = @TitleAr + N' - كلية الإدارة والاقتصاد - جامعة الحلة',
                SeoDescription = @SummaryAr, Status = 2, IsPublished = 1,
                PublishedAtUtc = COALESCE(PublishedAtUtc, @Now), UpdatedAtUtc = @Now
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
                @TitleAr + N' - كلية الإدارة والاقتصاد - جامعة الحلة',
                @SummaryAr, NULL, 2, 1, @Now, @Now
            );

        IF EXISTS (SELECT 1 FROM dbo.PageTranslations WHERE PageId = @PageId AND LanguageCode = N'en')
            UPDATE dbo.PageTranslations
            SET Title = @TitleEn, Summary = @SummaryEn, Content = NULL,
                SeoTitle = @TitleEn + N' - College of Administration and Economics - University of Hilla',
                SeoDescription = @SummaryEn, Status = 2, IsPublished = 1,
                PublishedAtUtc = COALESCE(PublishedAtUtc, @Now), UpdatedAtUtc = @Now
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
                @TitleEn + N' - College of Administration and Economics - University of Hilla',
                @SummaryEn, NULL, 2, 1, @Now, @Now
            );

        DELETE B
        FROM dbo.PageBlocks B
        INNER JOIN dbo.PageSections S ON S.Id = B.PageSectionId
        WHERE S.PageId = @PageId AND S.InternalName LIKE N'admeco-internal-%';

        DELETE FROM dbo.PageSections
        WHERE PageId = @PageId AND InternalName LIKE N'admeco-internal-%';

        IF @DocumentKey IS NOT NULL
        BEGIN
            SELECT TOP (1) @DocumentFileId = D.Id
            FROM dbo.DocumentFiles D
            INNER JOIN @LocalDocuments L ON L.FilePath = D.FilePath
            WHERE L.DocumentKey = @DocumentKey AND D.IsDeleted = 0
            ORDER BY D.Id;
        END

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
            CASE WHEN @SectionType = 24 THEN @DocumentFolderId ELSE NULL END,
            CASE WHEN @SectionType = 24 THEN @DocumentFileId ELSE NULL END,
            900,
            CASE WHEN @SectionType = 24 THEN 0 ELSE 1 END,
            1, 1, 0,
            CASE WHEN @SectionType = 24
                 THEN N'admeco-internal-page admeco-internal-pdf uw-college-document-panel'
                 ELSE N'admeco-internal-page admeco-internal-richtext uw-college-section' END,
            N'admeco-' + @PageKey,
            1, 0, 0, 10, @Now
        );

        FETCH NEXT FROM PageCursor INTO @PageKey, @SystemName, @Slug, @TitleAr, @TitleEn,
            @SummaryAr, @SummaryEn, @ContentAr, @ContentEn, @SectionType, @DocumentKey, @DisplayOrder;
    END

    CLOSE PageCursor;
    DEALLOCATE PageCursor;

    /* 4) إعادة بناء فرع "عن الكلية" فقط */
    DECLARE @AboutParentId int, @AccreditationMenuItemId int;

    SELECT TOP (1) @AboutParentId = Id
    FROM dbo.SiteMenuItems
    WHERE SiteMenuId = @MenuId
      AND ParentId IS NULL
      AND IsDeleted = 0
      AND
      (
          TitleAr IN (N'عن الكلية', N'حول الكلية')
          OR TitleEn IN (N'About the College', N'About')
      )
    ORDER BY Id;

    IF @AboutParentId IS NULL
    BEGIN
        INSERT dbo.SiteMenuItems
        (
            SiteMenuId, ParentId, PageId, TitleAr, TitleEn, Url,
            OpenInNewTab, IsActive, IsDeleted, DisplayOrder, CreatedAtUtc
        )
        VALUES
        (
            @MenuId, NULL, NULL, N'عن الكلية', N'About the College', N'#',
            0, 1, 0, 20, @Now
        );
        SET @AboutParentId = CONVERT(int, SCOPE_IDENTITY());
    END
    ELSE
    BEGIN
        UPDATE dbo.SiteMenuItems
        SET PageId = NULL, TitleAr = N'عن الكلية', TitleEn = N'About the College',
            Url = N'#', OpenInNewTab = 0, IsActive = 1, IsDeleted = 0,
            DisplayOrder = 20, UpdatedAtUtc = @Now
        WHERE Id = @AboutParentId;
    END

    DELETE GrandChild
    FROM dbo.SiteMenuItems GrandChild
    INNER JOIN dbo.SiteMenuItems Child ON Child.Id = GrandChild.ParentId
    WHERE Child.SiteMenuId = @MenuId AND Child.ParentId = @AboutParentId;

    DELETE FROM dbo.SiteMenuItems
    WHERE SiteMenuId = @MenuId AND ParentId = @AboutParentId;

    DECLARE @MenuItems TABLE
    (
        PageKey nvarchar(80) NOT NULL,
        TitleAr nvarchar(300) NOT NULL,
        TitleEn nvarchar(300) NOT NULL,
        DisplayOrder int NOT NULL
    );

    INSERT @MenuItems (PageKey, TitleAr, TitleEn, DisplayOrder)
    VALUES
    (N'dean-message', N'كلمة السيد العميد', N'Dean''s Message', 10),
    (N'vision-mission-goals', N'الرؤية والرسالة والأهداف', N'Vision, Mission and Goals', 20),
    (N'strategic-plan', N'الخطة الاستراتيجية', N'Strategic Plan', 30),
    (N'organizational-structure', N'الهيكل التنظيمي', N'Organizational Structure', 40),
    (N'course-descriptions', N'وصف المقررات', N'Course Descriptions', 50),
    (N'academic-program', N'وصف البرنامج الأكاديمي', N'Academic Programme Description', 60),
    (N'quality-policy', N'سياسة الجودة', N'Quality Policy', 70),
    (N'accreditation', N'الاعتماد الأكاديمي', N'Academic Accreditation', 80),
    (N'college-council', N'مجلس الكلية', N'College Council', 90),
    (N'contact', N'تواصل مع الكلية', N'Contact the College', 100);

    INSERT dbo.SiteMenuItems
    (
        SiteMenuId, ParentId, PageId, TitleAr, TitleEn, Url,
        OpenInNewTab, IsActive, IsDeleted, DisplayOrder, CreatedAtUtc
    )
    SELECT @MenuId, @AboutParentId, P.Id, M.TitleAr, M.TitleEn, NULL,
           0, 1, 0, M.DisplayOrder, @Now
    FROM @MenuItems M
    INNER JOIN @InternalPages I ON I.PageKey = M.PageKey
    INNER JOIN dbo.Pages P ON P.SystemName = I.SystemName AND P.IsDeleted = 0;

    SELECT TOP (1) @AccreditationMenuItemId = MI.Id
    FROM dbo.SiteMenuItems MI
    INNER JOIN dbo.Pages P ON P.Id = MI.PageId
    WHERE MI.SiteMenuId = @MenuId
      AND MI.ParentId = @AboutParentId
      AND P.SystemName = N'college_administration_economics_academic_accreditation'
      AND MI.IsDeleted = 0
    ORDER BY MI.Id;

    IF @AccreditationMenuItemId IS NULL
        THROW 53003, N'تعذر إنشاء عنصر قائمة الاعتماد الأكاديمي.', 1;

    DECLARE @AccreditationChildren TABLE
    (
        PageKey nvarchar(80) NOT NULL,
        TitleAr nvarchar(300) NOT NULL,
        TitleEn nvarchar(300) NOT NULL,
        DisplayOrder int NOT NULL
    );

    INSERT @AccreditationChildren (PageKey, TitleAr, TitleEn, DisplayOrder)
    VALUES
    (N'accreditation-updates', N'مستجدات الاعتماد الأكاديمي', N'Academic Accreditation Updates', 10),
    (N'accreditation-agenda', N'أجندة الاعتماد الأكاديمي', N'Academic Accreditation Agenda', 20),
    (N'self-evaluation-report', N'تقرير التقييم الذاتي', N'Self-Evaluation Report', 30);

    INSERT dbo.SiteMenuItems
    (
        SiteMenuId, ParentId, PageId, TitleAr, TitleEn, Url,
        OpenInNewTab, IsActive, IsDeleted, DisplayOrder, CreatedAtUtc
    )
    SELECT @MenuId, @AccreditationMenuItemId, P.Id, M.TitleAr, M.TitleEn, NULL,
           0, 1, 0, M.DisplayOrder, @Now
    FROM @AccreditationChildren M
    INNER JOIN @InternalPages I ON I.PageKey = M.PageKey
    INNER JOIN dbo.Pages P ON P.SystemName = I.SystemName AND P.IsDeleted = 0;

    /* لا يتم تعديل أي رابط يقع خارج فرع عن الكلية */
    UPDATE dbo.SiteMenuItems
    SET Url = NULL, OpenInNewTab = 0, UpdatedAtUtc = @Now
    WHERE SiteMenuId = @MenuId
      AND Url LIKE N'%account.hilla-unc.edu.iq%'
      AND (ParentId = @AboutParentId OR ParentId = @AccreditationMenuItemId);

    COMMIT TRANSACTION;

    SELECT
        @CollegeId AS CollegeId,
        @MenuId AS MenuId,
        @DocumentFolderId AS DocumentFolderId,
        (SELECT COUNT(*) FROM @InternalPages) AS InternalPagesPrepared,
        (SELECT COUNT(*) FROM @LocalDocuments) AS LocalDocumentsRegistered,
        (SELECT COUNT(*)
         FROM dbo.SiteMenuItems
         WHERE SiteMenuId = @MenuId
           AND Url LIKE N'%account.hilla-unc.edu.iq%'
           AND (ParentId = @AboutParentId OR ParentId = @AccreditationMenuItemId)) AS ExternalLinksRemainingInAboutBranch,
        N'تم إنشاء صفحات عن الكلية وربط القائمة داخلياً وتسجيل ملفات PDF المحلية بنجاح.' AS ResultMessage;
END TRY
BEGIN CATCH
    IF CURSOR_STATUS('local', 'PageCursor') >= -1
    BEGIN
        IF CURSOR_STATUS('local', 'PageCursor') > -1 CLOSE PageCursor;
        DEALLOCATE PageCursor;
    END

    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    THROW;
END CATCH;
