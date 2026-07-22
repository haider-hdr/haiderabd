/*
    UniWeb - College of Administration and Economics
    Internal CMS pages, internal menu links, and locally stored documents

    التنفيذ من SQL Server Management Studio (SSMS)

    النتيجة:
    - تحويل عناصر قائمة "عن الكلية" إلى صفحات داخلية في UniWeb مرتبطة بواسطة PageId.
    - إنشاء صفحات عربية وإنكليزية قابلة للتحرير من لوحة CMS.
    - تسجيل الخطة الاستراتيجية وتقرير التقييم الذاتي داخل DocumentFiles.
    - عرض ملفات PDF من مسارات محلية تحت wwwroot/uploads.
    - إزالة روابط التشغيل القديمة إلى account.hilla-unc.edu.iq من قائمة الكلية فقط.
    - لا يوجد Migration أو Seeder أو تعديل Models/Controllers.

    قبل التنفيذ:
    1) شغّل Tools/AdministrationEconomics/Download-AdministrationEconomicsDocuments.cmd.
    2) خذ نسخة احتياطية من قاعدة البيانات.
    3) اختر قاعدة بيانات UniWeb الصحيحة ثم نفّذ السكربت كاملاً.
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
    ORDER BY
        CASE WHEN Slug = N'colleges/administration-economics' THEN 0 ELSE 1 END,
        Id;

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

    /* ================================================================
       1) مجلد المستندات والملفات المحلية
       ================================================================ */
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
            N'الخطة الاستراتيجية ووثائق الجودة والتقييم والاعتماد الخاصة بكلية الإدارة والاقتصاد والمحفوظة محلياً داخل UniWeb.',
            N'Strategic planning, quality, evaluation, and accreditation documents of the College of Administration and Economics stored locally in UniWeb.',
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
            DescriptionAr = N'الخطة الاستراتيجية ووثائق الجودة والتقييم والاعتماد الخاصة بكلية الإدارة والاقتصاد والمحفوظة محلياً داخل UniWeb.',
            DescriptionEn = N'Strategic planning, quality, evaluation, and accreditation documents of the College of Administration and Economics stored locally in UniWeb.',
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
        N'الخطة الاستراتيجية الرسمية للكلية محفوظة محلياً داخل موقع UniWeb.',
        N'The official College strategic plan stored locally in UniWeb.',
        10
    ),
    (
        N'self-evaluation-report',
        N'/uploads/colleges/administration-economics/documents/administration-economics-self-evaluation-report.pdf',
        N'administration-economics-self-evaluation-report.pdf',
        N'تقرير التقييم الذاتي لكلية الإدارة والاقتصاد',
        N'College of Administration and Economics Self-Evaluation Report',
        N'تقرير التقييم الذاتي الرسمي للكلية محفوظ محلياً داخل نظام المستندات.',
        N'The official College self-evaluation report stored locally in the document system.',
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
        SELECT 1
        FROM dbo.DocumentFiles D
        WHERE D.FilePath = S.FilePath
    );

    /* ================================================================
       2) تعريف الصفحات الداخلية
       SectionType 2 = RichText, SectionType 24 = PdfViewer
       ================================================================ */
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
        N'dean-message',
        N'college_administration_economics_dean_message',
        N'colleges/administration-economics/about/dean-message',
        N'كلمة السيد العميد', N'Dean''s Message',
        N'كلمة عمادة كلية الإدارة والاقتصاد بشأن التعليم والبحث العلمي وخدمة المجتمع.',
        N'A message from the College leadership on education, research, and community service.',
        N'<div class="uw-college-rich-content"><p class="lead"><strong>الدكتور حسين ديكان درويش</strong><br>عميد كلية الإدارة والاقتصاد</p><p>نرحب بطلبتنا الأعزاء وأعضاء الهيئة التدريسية والضيوف في كلية الإدارة والاقتصاد، التي تسعى إلى تقديم تعليم أكاديمي نوعي وإعداد خريجين مؤهلين يمتلكون المعرفة والمهارات اللازمة للنجاح في مجالات الإدارة والمحاسبة والاقتصاد.</p><p>تؤمن الكلية بأن الاستثمار في العلم والمعرفة هو الأساس لبناء مستقبل أفضل، ولذلك تعمل على تطوير المناهج، وتشجيع الابتكار والبحث العلمي، وتوفير بيئة تعليمية محفزة تدعم قدرات الطلبة وتلبي متطلبات سوق العمل.</p><p>كما تحرص العمادة على بناء شراكات أكاديمية واقتصادية فاعلة، وتعزيز خدمة المجتمع، وترسيخ قيم الجودة والنزاهة والمسؤولية المهنية.</p></div>',
        N'<div class="uw-college-rich-content"><p class="lead"><strong>Dr Hussein Dikan Darwish</strong><br>Dean of the College of Administration and Economics</p><p>We welcome our students, faculty members, and guests to the College of Administration and Economics. The College seeks to provide high-quality academic education and prepare qualified graduates with the knowledge and skills required for administration, accounting, and economics.</p><p>The College believes that investment in knowledge is the foundation of a better future. It therefore develops curricula, supports innovation and scientific research, and provides a motivating learning environment that strengthens student capabilities and responds to labour-market needs.</p><p>The Deanship also works to build effective academic and economic partnerships, serve the community, and promote quality, integrity, and professional responsibility.</p></div>',
        2, NULL, 10
    ),
    (
        N'vision-mission-goals',
        N'college_administration_economics_vision_mission_goals',
        N'colleges/administration-economics/about/vision-mission-goals',
        N'الرؤية والرسالة والأهداف', N'Vision, Mission and Goals',
        N'المرتكزات الأكاديمية والمهنية لكلية الإدارة والاقتصاد.',
        N'The academic and professional foundations of the College of Administration and Economics.',
        N'<div class="uw-college-rich-content"><h3>الرؤية</h3><p>أن تكون كلية الإدارة والاقتصاد رائدة في تقديم تعليم متميز في مجالي المحاسبة والاقتصاد، لإعداد قادة إداريين وخبراء اقتصاديين ذوي كفاءة عالية يساهمون في تعزيز التطور الاقتصادي والمالي المستدام.</p><h3>الرسالة</h3><p>تقديم برامج أكاديمية متطورة في مجالي المحاسبة والاقتصاد، تهدف إلى تأهيل خريجين يمتلكون المعرفة النظرية والمهارات العملية اللازمة لتحقيق التميز في مجالات الأعمال والإدارة المالية والتخطيط الاقتصادي، مع التركيز على الابتكار وتعزيز التنمية المستدامة وخدمة المجتمع.</p><h3>الأهداف</h3><ol><li>تطوير برامج أكاديمية في الإدارة والمحاسبة والاقتصاد تواكب احتياجات سوق العمل.</li><li>تنمية المهارات القيادية والإدارية والتحليلية لدى الطلبة.</li><li>دعم البحث العلمي في المحاسبة والاقتصاد واستراتيجيات الأعمال.</li><li>تعزيز الشراكات المهنية والتدريب الميداني مع المؤسسات العامة والخاصة.</li><li>تشجيع الابتكار والمسؤولية المجتمعية والمساهمة في التنمية المستدامة.</li></ol></div>',
        N'<div class="uw-college-rich-content"><h3>Vision</h3><p>To be a leading College in providing distinguished education in accounting and economics and in preparing highly competent administrative leaders and economic experts who contribute to sustainable economic and financial development.</p><h3>Mission</h3><p>To provide advanced academic programmes in accounting and economics that prepare graduates with the theoretical knowledge and practical skills needed for excellence in business, financial management, and economic planning, with a focus on innovation, sustainable development, and community service.</p><h3>Goals</h3><ol><li>Develop academic programmes in administration, accounting, and economics that respond to labour-market needs.</li><li>Develop students'' leadership, administrative, and analytical skills.</li><li>Support scientific research in accounting, economics, and business strategy.</li><li>Strengthen professional partnerships and field training with public and private institutions.</li><li>Promote innovation, social responsibility, and sustainable development.</li></ol></div>',
        2, NULL, 20
    ),
    (
        N'strategic-plan',
        N'college_administration_economics_strategic_plan',
        N'colleges/administration-economics/about/strategic-plan',
        N'الخطة الاستراتيجية', N'Strategic Plan',
        N'عرض وتنزيل الخطة الاستراتيجية للكلية من داخل موقع UniWeb.',
        N'View and download the College strategic plan from within UniWeb.',
        NULL, NULL, 24, N'strategic-plan', 30
    ),
    (
        N'organizational-structure',
        N'college_administration_economics_organizational_structure',
        N'colleges/administration-economics/about/organizational-structure',
        N'الهيكل التنظيمي', N'Organizational Structure',
        N'عرض مبسط للبنية الأكاديمية والإدارية للكلية.',
        N'An overview of the College academic and administrative structure.',
        N'<div class="uw-college-rich-content"><div class="row g-3 text-center"><div class="col-12"><div class="p-4 border rounded-4 bg-light"><strong>مجلس الكلية</strong><div class="text-muted mt-2">الجهة الأكاديمية والإدارية العليا في الكلية</div></div></div><div class="col-12"><div class="p-4 border rounded-4"><strong>عمادة كلية الإدارة والاقتصاد</strong><div class="text-muted mt-2">القيادة الأكاديمية والإدارة والمتابعة المؤسسية</div></div></div><div class="col-md-4"><div class="p-4 border rounded-4 h-100"><strong>قسم المحاسبة</strong><div class="text-muted mt-2">التعليم والبحث العلمي والبرنامج الأكاديمي</div></div></div><div class="col-md-4"><div class="p-4 border rounded-4 h-100"><strong>الشعب والوحدات العلمية</strong><div class="text-muted mt-2">ضمان الجودة والتعليم المستمر والأنشطة والبحث العلمي</div></div></div><div class="col-md-4"><div class="p-4 border rounded-4 h-100"><strong>الشعب والوحدات الإدارية</strong><div class="text-muted mt-2">شؤون الطلبة والخدمات الإدارية والدعم المؤسسي</div></div></div></div><p class="text-muted mt-4">يمكن تحديث التفاصيل والمسميات من لوحة إدارة المحتوى عند اعتماد نسخة تنظيمية أحدث.</p></div>',
        N'<div class="uw-college-rich-content"><div class="row g-3 text-center"><div class="col-12"><div class="p-4 border rounded-4 bg-light"><strong>College Council</strong><div class="text-muted mt-2">The College''s highest academic and administrative body</div></div></div><div class="col-12"><div class="p-4 border rounded-4"><strong>College Deanship</strong><div class="text-muted mt-2">Academic leadership, administration, and institutional follow-up</div></div></div><div class="col-md-4"><div class="p-4 border rounded-4 h-100"><strong>Department of Accounting</strong><div class="text-muted mt-2">Teaching, research, and the academic programme</div></div></div><div class="col-md-4"><div class="p-4 border rounded-4 h-100"><strong>Academic Units</strong><div class="text-muted mt-2">Quality assurance, continuing education, activities, and research</div></div></div><div class="col-md-4"><div class="p-4 border rounded-4 h-100"><strong>Administrative Units</strong><div class="text-muted mt-2">Student affairs, administration, and institutional support</div></div></div></div><p class="text-muted mt-4">Details and titles can be updated through the CMS when a newer approved organisational structure is issued.</p></div>',
        2, NULL, 40
    ),
    (
        N'course-descriptions',
        N'college_administration_economics_course_descriptions',
        N'colleges/administration-economics/about/course-descriptions',
        N'وصف المقررات', N'Course Descriptions',
        N'محاور المقررات العلمية والعملية في برنامج المحاسبة.',
        N'Academic and practical course areas in the Accounting programme.',
        N'<div class="uw-college-rich-content"><p>تغطي مقررات قسم المحاسبة المعارف والمهارات الأساسية والمتقدمة التي يحتاجها الطالب في البيئة المالية والإدارية الحديثة.</p><div class="row g-3"><div class="col-md-6"><div class="p-4 border rounded-4 h-100"><h4>المحاسبة الأساسية والمالية</h4><p>المبادئ المحاسبية، التسجيل والترحيل، إعداد القوائم المالية، وتحليل العمليات المالية.</p></div></div><div class="col-md-6"><div class="p-4 border rounded-4 h-100"><h4>المحاسبة الإدارية والتكاليف</h4><p>قياس التكاليف، التخطيط والرقابة، دعم القرار، والموازنات.</p></div></div><div class="col-md-6"><div class="p-4 border rounded-4 h-100"><h4>التدقيق والضرائب</h4><p>أسس التدقيق والرقابة، التشريعات الضريبية، والالتزام المهني.</p></div></div><div class="col-md-6"><div class="p-4 border rounded-4 h-100"><h4>نظم المعلومات والتحليل المالي</h4><p>نظم المعلومات المحاسبية، التطبيقات الرقمية، وتحليل القوائم والمؤشرات المالية.</p></div></div></div><p class="text-muted mt-4">تُضاف ملفات وصف المقررات التفصيلية المعتمدة إلى مكتبة مستندات الكلية من لوحة الإدارة عند نشرها رسمياً.</p></div>',
        N'<div class="uw-college-rich-content"><p>The Accounting Department courses cover the foundational and advanced knowledge and skills required in modern financial and administrative environments.</p><div class="row g-3"><div class="col-md-6"><div class="p-4 border rounded-4 h-100"><h4>Basic and Financial Accounting</h4><p>Accounting principles, recording and posting, financial statements, and transaction analysis.</p></div></div><div class="col-md-6"><div class="p-4 border rounded-4 h-100"><h4>Managerial and Cost Accounting</h4><p>Cost measurement, planning and control, decision support, and budgeting.</p></div></div><div class="col-md-6"><div class="p-4 border rounded-4 h-100"><h4>Auditing and Taxation</h4><p>Auditing and control foundations, tax legislation, and professional compliance.</p></div></div><div class="col-md-6"><div class="p-4 border rounded-4 h-100"><h4>Information Systems and Financial Analysis</h4><p>Accounting information systems, digital applications, and analysis of statements and financial indicators.</p></div></div></div><p class="text-muted mt-4">Approved detailed course-description files can be added to the College document library through the administration panel when officially published.</p></div>',
        2, NULL, 50
    ),
    (
        N'academic-program',
        N'college_administration_economics_academic_program',
        N'colleges/administration-economics/about/academic-program-description',
        N'وصف البرنامج الأكاديمي', N'Academic Programme Description',
        N'وصف داخلي لبرنامج المحاسبة ومخرجاته ومجالات عمل الخريجين.',
        N'An internal overview of the Accounting programme, outcomes, and graduate careers.',
        N'<div class="uw-college-rich-content"><h3>برنامج المحاسبة</h3><p>يُعنى البرنامج بدراسة الأنظمة المالية والمحاسبية وإعداد الطلبة لفهم العمليات المحاسبية وتحليل البيانات وإعداد القوائم المالية ومراجعتها وفق الأطر المهنية والقانونية.</p><h3>المعارف والمهارات</h3><ul><li>تطبيق المبادئ والمعايير المحاسبية في تسجيل العمليات وإعداد التقارير.</li><li>تحليل القوائم المالية والمؤشرات ودعم القرارات الإدارية.</li><li>استخدام نظم المعلومات المحاسبية والتطبيقات الرقمية.</li><li>فهم التدقيق والرقابة والتكاليف والضرائب.</li><li>الالتزام بالنزاهة والموضوعية وأخلاقيات المهنة.</li></ul><h3>مجالات العمل</h3><p>المصارف، شركات ومكاتب التدقيق، المؤسسات الحكومية، الشركات العامة والخاصة، المحاسبة القانونية، والاستشارات المالية.</p></div>',
        N'<div class="uw-college-rich-content"><h3>Accounting Programme</h3><p>The programme studies financial and accounting systems and prepares students to understand accounting processes, analyse data, prepare financial statements, and review them within professional and legal frameworks.</p><h3>Knowledge and Skills</h3><ul><li>Apply accounting principles and standards to recording and reporting.</li><li>Analyse financial statements and indicators and support management decisions.</li><li>Use accounting information systems and digital applications.</li><li>Understand auditing, control, costing, and taxation.</li><li>Follow integrity, objectivity, and professional ethics.</li></ul><h3>Career Fields</h3><p>Banks, audit firms, government institutions, public and private companies, legal accounting, and financial consulting.</p></div>',
        2, NULL, 60
    ),
    (
        N'quality-policy',
        N'college_administration_economics_quality_policy',
        N'colleges/administration-economics/about/quality-policy',
        N'سياسة الجودة', N'Quality Policy',
        N'التزام الكلية بجودة التعليم والبحث والإدارة والتحسين المستمر.',
        N'The College commitment to educational, research, and administrative quality and continuous improvement.',
        N'<div class="uw-college-rich-content"><p>تلتزم كلية الإدارة والاقتصاد بتطبيق نظام جودة يدعم رسالتها الأكاديمية ويرفع كفاءة مخرجاتها التعليمية والبحثية والإدارية.</p><ol><li>تقديم تعليم عالي الجودة ينسجم مع المعايير الأكاديمية ومتطلبات سوق العمل.</li><li>تحديث البرامج والمناهج بصورة دورية وفق التطورات العلمية والمهنية.</li><li>تنمية قدرات أعضاء الهيئة التدريسية والكوادر الإدارية بالتدريب المستمر.</li><li>دعم البحث العلمي الرصين وربطه بالقضايا الاقتصادية والمالية والمجتمعية.</li><li>تعزيز التفاعل مع المجتمع والمؤسسات وأصحاب العلاقة.</li><li>قياس رضا الطلبة وتحسين تجربة التعلم والخدمات الجامعية.</li><li>تطبيق إجراءات إدارية كفوءة وشفافة وتعزيز المساءلة.</li><li>التقييم الدوري للأداء والاستفادة من النتائج في التحسين المستمر.</li></ol></div>',
        N'<div class="uw-college-rich-content"><p>The College of Administration and Economics applies a quality system that supports its academic mission and improves educational, research, and administrative outcomes.</p><ol><li>Provide high-quality education aligned with academic standards and labour-market needs.</li><li>Periodically update programmes and curricula in response to scientific and professional developments.</li><li>Develop faculty and administrative staff through continuous training.</li><li>Support rigorous research connected to economic, financial, and community issues.</li><li>Strengthen engagement with the community, institutions, and stakeholders.</li><li>Measure student satisfaction and improve learning and university services.</li><li>Apply efficient and transparent administrative procedures and strengthen accountability.</li><li>Periodically evaluate performance and use results for continuous improvement.</li></ol></div>',
        2, NULL, 70
    ),
    (
        N'accreditation',
        N'college_administration_economics_academic_accreditation',
        N'colleges/administration-economics/about/academic-accreditation',
        N'الاعتماد الأكاديمي', N'Academic Accreditation',
        N'بوابة داخلية لوثائق الجودة والاعتماد والتقويم والتحسين المستمر.',
        N'An internal gateway to quality, accreditation, evaluation, and continuous-improvement resources.',
        N'<div class="uw-college-rich-content"><p>تجمع هذه الصفحة المكونات والوثائق المنشورة ذات الصلة بالجودة والاعتماد الأكاديمي والتحسين المستمر في كلية الإدارة والاقتصاد.</p><div class="row g-3"><div class="col-md-6"><a class="d-block p-4 border rounded-4 text-decoration-none h-100" href="/ar/pages/colleges/administration-economics/about/quality-policy"><strong>سياسة الجودة</strong><span class="d-block text-muted mt-2">مرتكزات ضمان الجودة والتطوير المستمر.</span></a></div><div class="col-md-6"><a class="d-block p-4 border rounded-4 text-decoration-none h-100" href="/ar/pages/colleges/administration-economics/about/academic-program-description"><strong>وصف البرنامج الأكاديمي</strong><span class="d-block text-muted mt-2">الأهداف والمخرجات ومجالات العمل.</span></a></div><div class="col-md-6"><a class="d-block p-4 border rounded-4 text-decoration-none h-100" href="/ar/pages/colleges/administration-economics/about/strategic-plan"><strong>الخطة الاستراتيجية</strong><span class="d-block text-muted mt-2">عرض الوثيقة الرسمية المحفوظة محلياً.</span></a></div><div class="col-md-6"><a class="d-block p-4 border rounded-4 text-decoration-none h-100" href="/ar/pages/colleges/administration-economics/about/academic-accreditation/self-evaluation-report"><strong>تقرير التقييم الذاتي</strong><span class="d-block text-muted mt-2">عرض التقرير من نظام المستندات.</span></a></div></div></div>',
        N'<div class="uw-college-rich-content"><p>This page brings together the published resources related to quality, academic accreditation, and continuous improvement at the College of Administration and Economics.</p><div class="row g-3"><div class="col-md-6"><a class="d-block p-4 border rounded-4 text-decoration-none h-100" href="/en/pages/colleges/administration-economics/about/quality-policy"><strong>Quality Policy</strong><span class="d-block text-muted mt-2">Quality assurance and continuous-improvement foundations.</span></a></div><div class="col-md-6"><a class="d-block p-4 border rounded-4 text-decoration-none h-100" href="/en/pages/colleges/administration-economics/about/academic-program-description"><strong>Academic Programme Description</strong><span class="d-block text-muted mt-2">Goals, outcomes, and career fields.</span></a></div><div class="col-md-6"><a class="d-block p-4 border rounded-4 text-decoration-none h-100" href="/en/pages/colleges/administration-economics/about/strategic-plan"><strong>Strategic Plan</strong><span class="d-block text-muted mt-2">View the official locally stored document.</span></a></div><div class="col-md-6"><a class="d-block p-4 border rounded-4 text-decoration-none h-100" href="/en/pages/colleges/administration-economics/about/academic-accreditation/self-evaluation-report"><strong>Self-Evaluation Report</strong><span class="d-block text-muted mt-2">View the report from the document system.</span></a></div></div></div>',
        2, NULL, 80
    ),
    (
        N'accreditation-updates',
        N'college_administration_economics_accreditation_updates',
        N'colleges/administration-economics/about/academic-accreditation/updates',
        N'مستجدات الاعتماد الأكاديمي', N'Academic Accreditation Updates',
        N'صفحة داخلية لنشر أخبار ومستجدات الاعتماد الأكاديمي.',
        N'An internal page for publishing academic accreditation updates.',
        N'<div class="uw-college-rich-content"><div class="alert alert-info rounded-4"><strong>صفحة مهيأة للنشر</strong><p class="mb-0 mt-2">لم يتضمن المصدر الرسمي المرسل مواد مستقلة موثقة بعنوان مستجدات الاعتماد الأكاديمي. تم إنشاء الصفحة داخل UniWeb لتحديثها من لوحة الإدارة عند نشر الأخبار والقرارات والوثائق الرسمية، من دون إضافة معلومات أو أرقام اعتماد غير موثقة.</p></div></div>',
        N'<div class="uw-college-rich-content"><div class="alert alert-info rounded-4"><strong>Publishing-ready page</strong><p class="mb-0 mt-2">The supplied official source did not contain independently verified material titled Academic Accreditation Updates. This internal UniWeb page is ready to be updated through the administration panel when official news, decisions, or documents are published; no unverified accreditation claims or numbers have been added.</p></div></div>',
        2, NULL, 90
    ),
    (
        N'accreditation-agenda',
        N'college_administration_economics_accreditation_agenda',
        N'colleges/administration-economics/about/academic-accreditation/agenda',
        N'أجندة الاعتماد الأكاديمي', N'Academic Accreditation Agenda',
        N'صفحة داخلية لنشر مواعيد وخطة أعمال الاعتماد الأكاديمي.',
        N'An internal page for publishing the academic accreditation agenda.',
        N'<div class="uw-college-rich-content"><div class="alert alert-secondary rounded-4"><strong>أجندة قابلة للتحديث</strong><p class="mb-0 mt-2">لم تُنشر في الروابط الرسمية المرسلة أجندة زمنية مستقلة موثقة. تم تجهيز هذه الصفحة لإضافة المواعيد واللجان والمهام من لوحة الإدارة بعد اعتمادها رسمياً، من دون اختلاق تواريخ أو مراحل غير منشورة.</p></div></div>',
        N'<div class="uw-college-rich-content"><div class="alert alert-secondary rounded-4"><strong>Updateable agenda</strong><p class="mb-0 mt-2">No independently verified accreditation timetable was published in the supplied official links. This page is prepared for adding approved dates, committees, and tasks through the administration panel without inventing unpublished stages or deadlines.</p></div></div>',
        2, NULL, 100
    ),
    (
        N'self-evaluation-report',
        N'college_administration_economics_self_evaluation_report',
        N'colleges/administration-economics/about/academic-accreditation/self-evaluation-report',
        N'تقرير التقييم الذاتي', N'Self-Evaluation Report',
        N'عرض وتنزيل تقرير التقييم الذاتي للكلية من داخل UniWeb.',
        N'View and download the College self-evaluation report from within UniWeb.',
        NULL, NULL, 24, N'self-evaluation-report', 110
    ),
    (
        N'college-council',
        N'college_administration_economics_college_council',
        N'colleges/administration-economics/about/college-council',
        N'مجلس الكلية', N'College Council',
        N'اختصاصات مجلس الكلية وآلية تحديث بيانات أعضائه.',
        N'College Council responsibilities and member-data maintenance.',
        N'<div class="uw-college-rich-content"><p>يمثل مجلس الكلية الجهة الأكاديمية والإدارية العليا داخل الكلية، ويتولى مناقشة الخطط والبرامج والشؤون العلمية والطلابية والإدارية وفق الصلاحيات والتعليمات الجامعية النافذة.</p><h3>المهام الرئيسة</h3><ul><li>مراجعة الخطط الأكاديمية والمناهج ومقترحات تطوير البرنامج.</li><li>متابعة الجودة ومخرجات التعلم والبحث العلمي.</li><li>مناقشة شؤون الطلبة والهيئة التدريسية واللجان العلمية.</li><li>دعم الشراكات وخدمة المجتمع والتدريب والتطوير.</li><li>متابعة تنفيذ القرارات والتوصيات المعتمدة.</li></ul><div class="alert alert-light border rounded-4">تُحدّث أسماء أعضاء المجلس وصفاتهم من لوحة إدارة المحتوى عند اعتماد القائمة الرسمية المحدثة؛ لم تُضف أسماء غير موثقة إلى هذه الصفحة.</div></div>',
        N'<div class="uw-college-rich-content"><p>The College Council is the College''s highest academic and administrative body. It discusses academic plans, programmes, scientific affairs, student matters, and administration within the applicable university regulations and authorities.</p><h3>Core Responsibilities</h3><ul><li>Review academic plans, curricula, and programme-development proposals.</li><li>Follow up quality, learning outcomes, and scientific research.</li><li>Discuss student, faculty, and scientific-committee matters.</li><li>Support partnerships, community service, training, and development.</li><li>Follow up the implementation of approved decisions and recommendations.</li></ul><div class="alert alert-light border rounded-4">Council member names and roles can be updated through the CMS when an updated official list is approved; no unverified names have been added.</div></div>',
        2, NULL, 120
    ),
    (
        N'contact',
        N'college_administration_economics_contact',
        N'colleges/administration-economics/about/contact',
        N'تواصل مع الكلية', N'Contact the College',
        N'بيانات الاتصال والموقع الرسمي لكلية الإدارة والاقتصاد.',
        N'Official contact and location details for the College of Administration and Economics.',
        N'<div class="uw-college-rich-content"><div class="row g-3"><div class="col-md-6"><div class="p-4 border rounded-4 h-100"><h4>العنوان</h4><p class="mb-0">العراق - بابل - الحلة، طريق الحلة - النجف، جامعة الحلة.</p></div></div><div class="col-md-6"><div class="p-4 border rounded-4 h-100"><h4>البريد الإلكتروني</h4><p class="mb-0"><a href="mailto:Management_and_Economics@hilla-unc.edu.iq">Management_and_Economics@hilla-unc.edu.iq</a></p></div></div></div><p class="text-muted mt-4">يمكن تعديل بيانات الاتصال وإضافة أرقام الهاتف والموقع الجغرافي من لوحة إدارة المحتوى عند اعتمادها رسمياً.</p></div>',
        N'<div class="uw-college-rich-content"><div class="row g-3"><div class="col-md-6"><div class="p-4 border rounded-4 h-100"><h4>Address</h4><p class="mb-0">University of Hilla, Hilla-Najaf Road, Babylon, Iraq.</p></div></div><div class="col-md-6"><div class="p-4 border rounded-4 h-100"><h4>Email</h4><p class="mb-0"><a href="mailto:Management_and_Economics@hilla-unc.edu.iq">Management_and_Economics@hilla-unc.edu.iq</a></p></div></div></div><p class="text-muted mt-4">Contact details, phone numbers, and location information can be updated through the CMS when officially approved.</p></div>',
        2, NULL, 130
    );

    /* ================================================================
       3) إنشاء أو تحديث الصفحات والترجمات والسكشنات
       ================================================================ */
    DECLARE
        @PageKey nvarchar(80), @SystemName nvarchar(150), @Slug nvarchar(300),
        @TitleAr nvarchar(300), @TitleEn nvarchar(300),
        @SummaryAr nvarchar(1000), @SummaryEn nvarchar(1000),
        @ContentAr nvarchar(max), @ContentEn nvarchar(max),
        @SectionType int, @DocumentKey nvarchar(80), @DisplayOrder int,
        @PageId int, @DocumentFileId int, @InternalName nvarchar(150);

    DECLARE PageCursor CURSOR LOCAL FAST_FORWARD FOR
    SELECT
        PageKey, SystemName, Slug,
        TitleAr, TitleEn, SummaryAr, SummaryEn,
        ContentAr, ContentEn, SectionType, DocumentKey, DisplayOrder
    FROM @InternalPages
    ORDER BY DisplayOrder;

    OPEN PageCursor;
    FETCH NEXT FROM PageCursor INTO
        @PageKey, @SystemName, @Slug,
        @TitleAr, @TitleEn, @SummaryAr, @SummaryEn,
        @ContentAr, @ContentEn, @SectionType, @DocumentKey, @DisplayOrder;

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
            SET Title = @TitleAr,
                Summary = @SummaryAr,
                Content = NULL,
                SeoTitle = @TitleAr + N' - كلية الإدارة والاقتصاد - جامعة الحلة',
                SeoDescription = @SummaryAr,
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
                @TitleAr + N' - كلية الإدارة والاقتصاد - جامعة الحلة',
                @SummaryAr, NULL,
                2, 1, @Now, @Now
            );

        IF EXISTS (SELECT 1 FROM dbo.PageTranslations WHERE PageId = @PageId AND LanguageCode = N'en')
            UPDATE dbo.PageTranslations
            SET Title = @TitleEn,
                Summary = @SummaryEn,
                Content = NULL,
                SeoTitle = @TitleEn + N' - College of Administration and Economics - University of Hilla',
                SeoDescription = @SummaryEn,
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
                @TitleEn + N' - College of Administration and Economics - University of Hilla',
                @SummaryEn, NULL,
                2, 1, @Now, @Now
            );

        DELETE B
        FROM dbo.PageBlocks B
        INNER JOIN dbo.PageSections S ON S.Id = B.PageSectionId
        WHERE S.PageId = @PageId
          AND S.InternalName LIKE N'admeco-internal-%';

        DELETE FROM dbo.PageSections
        WHERE PageId = @PageId
          AND InternalName LIKE N'admeco-internal-%';

        IF @DocumentKey IS NOT NULL
        BEGIN
            SELECT TOP (1) @DocumentFileId = D.Id
            FROM dbo.DocumentFiles D
            INNER JOIN @LocalDocuments L ON L.FilePath = D.FilePath
            WHERE L.DocumentKey = @DocumentKey
              AND D.IsDeleted = 0
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
            1,
            1, 0,
            CASE WHEN @SectionType = 24
                 THEN N'admeco-internal-page admeco-internal-pdf uw-college-document-panel'
                 ELSE N'admeco-internal-page admeco-internal-richtext uw-college-section' END,
            N'admeco-' + @PageKey,
            1, 0, 0, 10, @Now
        );

        FETCH NEXT FROM PageCursor INTO
            @PageKey, @SystemName, @Slug,
            @TitleAr, @TitleEn, @SummaryAr, @SummaryEn,
            @ContentAr, @ContentEn, @SectionType, @DocumentKey, @DisplayOrder;
    END

    CLOSE PageCursor;
    DEALLOCATE PageCursor;

    /* ================================================================
       4) إعادة بناء قائمة "عن الكلية" بروابط داخلية فقط
       ================================================================ */
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
            SiteMenuId, ParentId, PageId,
            TitleAr, TitleEn, Url,
            OpenInNewTab, IsActive, IsDeleted,
            DisplayOrder, CreatedAtUtc
        )
        VALUES
        (
            @MenuId, NULL, NULL,
            N'عن الكلية', N'About the College', N'#',
            0, 1, 0, 20, @Now
        );
        SET @AboutParentId = CONVERT(int, SCOPE_IDENTITY());
    END
    ELSE
    BEGIN
        UPDATE dbo.SiteMenuItems
        SET PageId = NULL,
            TitleAr = N'عن الكلية',
            TitleEn = N'About the College',
            Url = N'#',
            OpenInNewTab = 0,
            IsActive = 1,
            IsDeleted = 0,
            DisplayOrder = 20,
            UpdatedAtUtc = @Now
        WHERE Id = @AboutParentId;
    END

    DELETE GrandChild
    FROM dbo.SiteMenuItems GrandChild
    INNER JOIN dbo.SiteMenuItems Child ON Child.Id = GrandChild.ParentId
    WHERE Child.SiteMenuId = @MenuId
      AND Child.ParentId = @AboutParentId;

    DELETE FROM dbo.SiteMenuItems
    WHERE SiteMenuId = @MenuId
      AND ParentId = @AboutParentId;

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
        SiteMenuId, ParentId, PageId,
        TitleAr, TitleEn, Url,
        OpenInNewTab, IsActive, IsDeleted,
        DisplayOrder, CreatedAtUtc
    )
    SELECT
        @MenuId,
        @AboutParentId,
        P.Id,
        M.TitleAr,
        M.TitleEn,
        NULL,
        0, 1, 0,
        M.DisplayOrder,
        @Now
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
        SiteMenuId, ParentId, PageId,
        TitleAr, TitleEn, Url,
        OpenInNewTab, IsActive, IsDeleted,
        DisplayOrder, CreatedAtUtc
    )
    SELECT
        @MenuId,
        @AccreditationMenuItemId,
        P.Id,
        M.TitleAr,
        M.TitleEn,
        NULL,
        0, 1, 0,
        M.DisplayOrder,
        @Now
    FROM @AccreditationChildren M
    INNER JOIN @InternalPages I ON I.PageKey = M.PageKey
    INNER JOIN dbo.Pages P ON P.SystemName = I.SystemName AND P.IsDeleted = 0;

    UPDATE dbo.SiteMenuItems
    SET Url = NULL,
        OpenInNewTab = 0,
        UpdatedAtUtc = @Now
    WHERE SiteMenuId = @MenuId
      AND Url LIKE N'%account.hilla-unc.edu.iq%';

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
           AND Url LIKE N'%account.hilla-unc.edu.iq%') AS RemainingOldExternalMenuLinks,
        N'تم إنشاء صفحات عن الكلية وربط القائمة داخلياً وتسجيل ملفات PDF المحلية بنجاح.' AS ResultMessage;
END TRY
BEGIN CATCH
    IF CURSOR_STATUS('local', 'PageCursor') >= -1
    BEGIN
        IF CURSOR_STATUS('local', 'PageCursor') > -1 CLOSE PageCursor;
        DEALLOCATE PageCursor;
    END

    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION;

    THROW;
END CATCH;
