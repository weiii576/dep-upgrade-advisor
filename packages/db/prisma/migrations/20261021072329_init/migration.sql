-- CreateExtension
CREATE EXTENSION IF NOT EXISTS vector;

-- CreateEnum
CREATE TYPE "dependency_type" AS ENUM ('prod', 'dev', 'peer', 'optional');

-- CreateEnum
CREATE TYPE "root_dependency_type" AS ENUM ('prod', 'dev');

-- CreateEnum
CREATE TYPE "advisory_severity" AS ENUM ('low', 'moderate', 'high', 'critical');

-- CreateEnum
CREATE TYPE "document_kind" AS ENUM ('advisory_description', 'release_notes', 'upgrade_policy');

-- CreateTable
CREATE TABLE "repository" (
    "id" UUID NOT NULL,
    "name" TEXT NOT NULL,

    CONSTRAINT "repository_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "package" (
    "id" UUID NOT NULL,
    "name" TEXT NOT NULL,

    CONSTRAINT "package_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "package_version" (
    "id" UUID NOT NULL,
    "packageId" UUID NOT NULL,
    "version" TEXT NOT NULL,
    "deprecated" BOOLEAN NOT NULL DEFAULT false,

    CONSTRAINT "package_version_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "package_version_dependency" (
    "packageVersionId" UUID NOT NULL,
    "dependsOnPackageId" UUID NOT NULL,
    "versionRange" TEXT NOT NULL,
    "type" "dependency_type" NOT NULL,

    CONSTRAINT "package_version_dependency_pkey" PRIMARY KEY ("packageVersionId","dependsOnPackageId","type")
);

-- CreateTable
CREATE TABLE "advisory" (
    "id" UUID NOT NULL,
    "osvId" TEXT NOT NULL,
    "severity" "advisory_severity",
    "summary" TEXT,
    "publishedAt" TIMESTAMPTZ NOT NULL,
    "modifiedAt" TIMESTAMPTZ NOT NULL,
    "withdrawnAt" TIMESTAMPTZ,
    "rawJson" JSONB NOT NULL,

    CONSTRAINT "advisory_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "advisory_package" (
    "id" UUID NOT NULL,
    "advisoryId" UUID NOT NULL,
    "packageId" UUID NOT NULL,
    "affectedRange" TEXT NOT NULL,

    CONSTRAINT "advisory_package_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "installation" (
    "id" UUID NOT NULL,
    "repositoryId" UUID NOT NULL,
    "packageVersionId" UUID NOT NULL,

    CONSTRAINT "installation_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "installation_edge" (
    "repositoryId" UUID NOT NULL,
    "installationId" UUID NOT NULL,
    "dependsOnInstallationId" UUID NOT NULL,

    CONSTRAINT "installation_edge_pkey" PRIMARY KEY ("installationId","dependsOnInstallationId")
);

-- CreateTable
CREATE TABLE "root_dependency" (
    "repositoryId" UUID NOT NULL,
    "installationId" UUID NOT NULL,
    "versionRange" TEXT NOT NULL,
    "type" "root_dependency_type" NOT NULL,

    CONSTRAINT "root_dependency_pkey" PRIMARY KEY ("repositoryId","installationId","type")
);

-- CreateTable
CREATE TABLE "document" (
    "id" UUID NOT NULL,
    "kind" "document_kind" NOT NULL,
    "title" TEXT,
    "content" TEXT NOT NULL,
    "sourceUrl" TEXT NOT NULL,
    "advisoryId" UUID,
    "packageVersionId" UUID,
    "repositoryId" UUID,
    "createdAt" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMPTZ NOT NULL,

    CONSTRAINT "document_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "chunk" (
    "id" UUID NOT NULL,
    "documentId" UUID NOT NULL,
    "ordinal" INTEGER NOT NULL,
    "content" TEXT NOT NULL,
    "embedding" vector(1536) NOT NULL,
    "embeddingModel" TEXT NOT NULL,
    "contentHash" CHAR(64) NOT NULL,

    CONSTRAINT "chunk_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "repository_name_key" ON "repository"("name");

-- CreateIndex
CREATE UNIQUE INDEX "package_name_key" ON "package"("name");

-- CreateIndex
CREATE UNIQUE INDEX "package_version_packageId_version_key" ON "package_version"("packageId", "version");

-- CreateIndex
CREATE INDEX "package_version_dependency_dependsOnPackageId_idx" ON "package_version_dependency"("dependsOnPackageId");

-- CreateIndex
CREATE UNIQUE INDEX "advisory_osvId_key" ON "advisory"("osvId");

-- CreateIndex
CREATE INDEX "advisory_package_packageId_idx" ON "advisory_package"("packageId");

-- CreateIndex
CREATE UNIQUE INDEX "advisory_package_advisoryId_packageId_key" ON "advisory_package"("advisoryId", "packageId");

-- CreateIndex
CREATE UNIQUE INDEX "installation_repositoryId_id_key" ON "installation"("repositoryId", "id");

-- CreateIndex
CREATE UNIQUE INDEX "installation_repositoryId_packageVersionId_key" ON "installation"("repositoryId", "packageVersionId");

-- CreateIndex
CREATE INDEX "installation_edge_repositoryId_dependsOnInstallationId_idx" ON "installation_edge"("repositoryId", "dependsOnInstallationId");

-- CreateIndex
CREATE UNIQUE INDEX "document_sourceUrl_key" ON "document"("sourceUrl");

-- CreateIndex
CREATE INDEX "document_kind_repositoryId_idx" ON "document"("kind", "repositoryId");

-- CreateIndex
CREATE INDEX "document_advisoryId_idx" ON "document"("advisoryId");

-- CreateIndex
CREATE INDEX "document_packageVersionId_idx" ON "document"("packageVersionId");

-- CreateIndex
CREATE INDEX "chunk_contentHash_embeddingModel_idx" ON "chunk"("contentHash", "embeddingModel");

-- CreateIndex
CREATE UNIQUE INDEX "chunk_documentId_embeddingModel_ordinal_key" ON "chunk"("documentId", "embeddingModel", "ordinal");

-- AddForeignKey
ALTER TABLE "package_version" ADD CONSTRAINT "package_version_packageId_fkey" FOREIGN KEY ("packageId") REFERENCES "package"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "package_version_dependency" ADD CONSTRAINT "package_version_dependency_packageVersionId_fkey" FOREIGN KEY ("packageVersionId") REFERENCES "package_version"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "package_version_dependency" ADD CONSTRAINT "package_version_dependency_dependsOnPackageId_fkey" FOREIGN KEY ("dependsOnPackageId") REFERENCES "package"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "advisory_package" ADD CONSTRAINT "advisory_package_advisoryId_fkey" FOREIGN KEY ("advisoryId") REFERENCES "advisory"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "advisory_package" ADD CONSTRAINT "advisory_package_packageId_fkey" FOREIGN KEY ("packageId") REFERENCES "package"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "installation" ADD CONSTRAINT "installation_repositoryId_fkey" FOREIGN KEY ("repositoryId") REFERENCES "repository"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "installation" ADD CONSTRAINT "installation_packageVersionId_fkey" FOREIGN KEY ("packageVersionId") REFERENCES "package_version"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "installation_edge" ADD CONSTRAINT "installation_edge_repositoryId_installationId_fkey" FOREIGN KEY ("repositoryId", "installationId") REFERENCES "installation"("repositoryId", "id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "installation_edge" ADD CONSTRAINT "installation_edge_repositoryId_dependsOnInstallationId_fkey" FOREIGN KEY ("repositoryId", "dependsOnInstallationId") REFERENCES "installation"("repositoryId", "id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "root_dependency" ADD CONSTRAINT "root_dependency_repositoryId_installationId_fkey" FOREIGN KEY ("repositoryId", "installationId") REFERENCES "installation"("repositoryId", "id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "document" ADD CONSTRAINT "document_advisoryId_fkey" FOREIGN KEY ("advisoryId") REFERENCES "advisory"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "document" ADD CONSTRAINT "document_packageVersionId_fkey" FOREIGN KEY ("packageVersionId") REFERENCES "package_version"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "document" ADD CONSTRAINT "document_repositoryId_fkey" FOREIGN KEY ("repositoryId") REFERENCES "repository"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "chunk" ADD CONSTRAINT "chunk_documentId_fkey" FOREIGN KEY ("documentId") REFERENCES "document"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- Decision 0002 section 1: document kind must match exactly one back-reference.
ALTER TABLE "document" ADD CONSTRAINT "document_kind_matches_reference" CHECK (
  ("kind" = 'advisory_description' AND "advisoryId" IS NOT NULL AND "packageVersionId" IS NULL AND "repositoryId" IS NULL)
  OR ("kind" = 'release_notes' AND "packageVersionId" IS NOT NULL AND "advisoryId" IS NULL AND "repositoryId" IS NULL)
  OR ("kind" = 'upgrade_policy' AND "repositoryId" IS NOT NULL AND "advisoryId" IS NULL AND "packageVersionId" IS NULL)
);
