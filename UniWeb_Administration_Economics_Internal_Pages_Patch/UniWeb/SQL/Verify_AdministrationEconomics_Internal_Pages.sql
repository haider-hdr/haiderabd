/*
    UniWeb - Verify College of Administration and Economics internal pages
    هذا السكربت للقراءة والتحقق فقط ولا يغيّر البيانات.
*/
SET NOCOUNT ON;

DECLARE @CollegeId int, @MenuId int;

SELECT TOP (1) @CollegeId = Id
FROM dbo.AcademicColleges
WHERE IsActive = 1
  AND
  (
      Slug = N'colleges/administration-economics'
      OR Code IN (N'ADMECON', N'ADMIN-ECON', N'AE', N'ACCOUNT')
      OR NameAr LIKE N'%الإدارة والاقتصاد%'
      OR NameAr LIKE N'%الادارة والاقتصاد%'
  )
ORDER BY CASE WHEN Slug = N'colleges/administration-economics' THEN 0 ELSE 1 END, Id;

SELECT @MenuId = CustomMenuId
FROM dbo.AcademicColleges
WHERE Id = @CollegeId;

PRINT N'1) ملخص الكلية والقائمة';
SELECT
    C.Id AS CollegeId,
    C.NameAr,
    C.NameEn,
    C.Code,
    C.Slug,
    C.HomePageId,
    C.CustomMenuId,
    M.NameAr AS MenuNameAr,
    M.SystemName AS MenuSystemName
FROM dbo.AcademicColleges C
LEFT JOIN dbo.SiteMenus M ON M.Id = C.CustomMenuId
WHERE C.Id = @CollegeId;

PRINT N'2) الصفحات الداخلية المنشأة';
SELECT
    P.Id,
    P.SystemName,
    P.Slug,
    P.IsPublished,
    P.IsDeleted,
    Ar.Title AS TitleAr,
    En.Title AS TitleEn,
    (SELECT COUNT(*) FROM dbo.PageSections S WHERE S.PageId = P.Id AND S.IsDeleted = 0) AS ActiveSections
FROM dbo.Pages P
LEFT JOIN dbo.PageTranslations Ar ON Ar.PageId = P.Id AND Ar.LanguageCode = N'ar'
LEFT JOIN dbo.PageTranslations En ON En.PageId = P.Id AND En.LanguageCode = N'en'
WHERE P.SystemName LIKE N'college_administration_economics_%'
ORDER BY P.DisplayOrder, P.Id;

PRINT N'3) صفحات ناقصة الترجمة أو السكشن';
SELECT
    P.Id,
    P.SystemName,
    P.Slug,
    CASE WHEN Ar.PageId IS NULL THEN 1 ELSE 0 END AS MissingArabic,
    CASE WHEN En.PageId IS NULL THEN 1 ELSE 0 END AS MissingEnglish,
    CASE WHEN S.PageId IS NULL THEN 1 ELSE 0 END AS MissingSection
FROM dbo.Pages P
LEFT JOIN dbo.PageTranslations Ar ON Ar.PageId = P.Id AND Ar.LanguageCode = N'ar'
LEFT JOIN dbo.PageTranslations En ON En.PageId = P.Id AND En.LanguageCode = N'en'
OUTER APPLY
(
    SELECT TOP (1) PS.PageId
    FROM dbo.PageSections PS
    WHERE PS.PageId = P.Id
      AND PS.IsActive = 1
      AND PS.IsHidden = 0
      AND PS.IsDeleted = 0
) S
WHERE P.SystemName LIKE N'college_administration_economics_%'
  AND (Ar.PageId IS NULL OR En.PageId IS NULL OR S.PageId IS NULL)
ORDER BY P.Id;

PRINT N'4) ملفات PDF المسجلة';
SELECT
    D.Id,
    D.TitleAr,
    D.TitleEn,
    D.FilePath,
    D.FileSizeBytes,
    D.ContentType,
    D.IsPdf,
    D.IsActive,
    D.IsDeleted,
    F.NameAr AS FolderNameAr
FROM dbo.DocumentFiles D
LEFT JOIN dbo.DocumentFolders F ON F.Id = D.DocumentFolderId
WHERE D.AcademicCollegeId = @CollegeId
  AND D.FilePath LIKE N'/uploads/colleges/administration-economics/documents/%'
ORDER BY D.DisplayOrder, D.Id;

PRINT N'5) سكشنات عارض PDF وربط الملفات';
SELECT
    P.SystemName,
    P.Slug,
    S.Id AS SectionId,
    S.SectionType,
    S.DocumentFolderId,
    S.DocumentFileId,
    S.PdfHeight,
    S.ShowDocumentDownloadButton,
    D.FilePath
FROM dbo.Pages P
INNER JOIN dbo.PageSections S ON S.PageId = P.Id
LEFT JOIN dbo.DocumentFiles D ON D.Id = S.DocumentFileId
WHERE P.SystemName LIKE N'college_administration_economics_%'
  AND S.SectionType = 24
  AND S.IsDeleted = 0
ORDER BY P.DisplayOrder, S.DisplayOrder;

PRINT N'6) بنية قائمة عن الكلية';
;WITH MenuTree AS
(
    SELECT
        MI.Id,
        MI.ParentId,
        MI.PageId,
        MI.TitleAr,
        MI.TitleEn,
        MI.Url,
        MI.DisplayOrder,
        0 AS MenuLevel,
        CAST(RIGHT(N'000000' + CONVERT(nvarchar(6), MI.DisplayOrder), 6) AS nvarchar(400)) AS SortPath
    FROM dbo.SiteMenuItems MI
    WHERE MI.SiteMenuId = @MenuId
      AND MI.ParentId IS NULL
      AND MI.IsDeleted = 0
      AND (MI.TitleAr IN (N'عن الكلية', N'حول الكلية') OR MI.TitleEn IN (N'About the College', N'About'))

    UNION ALL

    SELECT
        C.Id,
        C.ParentId,
        C.PageId,
        C.TitleAr,
        C.TitleEn,
        C.Url,
        C.DisplayOrder,
        P.MenuLevel + 1,
        CAST(P.SortPath + N'/' + RIGHT(N'000000' + CONVERT(nvarchar(6), C.DisplayOrder), 6) AS nvarchar(400))
    FROM dbo.SiteMenuItems C
    INNER JOIN MenuTree P ON P.Id = C.ParentId
    WHERE C.SiteMenuId = @MenuId
      AND C.IsDeleted = 0
)
SELECT
    REPLICATE(N'— ', MenuLevel) + TitleAr AS MenuItemAr,
    TitleEn,
    MenuLevel,
    PageId,
    Url,
    P.Slug AS InternalPageSlug,
    MT.DisplayOrder
FROM MenuTree MT
LEFT JOIN dbo.Pages P ON P.Id = MT.PageId
ORDER BY SortPath;

PRINT N'7) الروابط الخارجية القديمة المتبقية';
SELECT
    MI.Id,
    MI.TitleAr,
    MI.TitleEn,
    MI.Url
FROM dbo.SiteMenuItems MI
WHERE MI.SiteMenuId = @MenuId
  AND MI.IsDeleted = 0
  AND MI.Url LIKE N'%account.hilla-unc.edu.iq%';

PRINT N'8) النتيجة الرقمية النهائية';
SELECT
    @CollegeId AS CollegeId,
    @MenuId AS MenuId,
    (SELECT COUNT(*) FROM dbo.Pages WHERE SystemName LIKE N'college_administration_economics_%' AND IsDeleted = 0) AS InternalPages,
    (SELECT COUNT(*)
     FROM dbo.DocumentFiles
     WHERE AcademicCollegeId = @CollegeId
       AND FilePath LIKE N'/uploads/colleges/administration-economics/documents/%'
       AND IsDeleted = 0) AS LocalDocuments,
    (SELECT COUNT(*)
     FROM dbo.SiteMenuItems
     WHERE SiteMenuId = @MenuId
       AND IsDeleted = 0
       AND Url LIKE N'%account.hilla-unc.edu.iq%') AS ExternalLinksRemainingInCollegeMenu;
