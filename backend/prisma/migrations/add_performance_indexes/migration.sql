-- CreateIndex for Transaction performance
-- Compound indexes for common query patterns

-- Index for listing transactions by user + type + date
CREATE INDEX IF NOT EXISTS "idx_transaction_user_type_date" ON "Transaction"("userId", "type", "transactionDate" DESC);

-- Index for transactions by client + type
CREATE INDEX IF NOT EXISTS "idx_transaction_client_type" ON "Transaction"("clientId", "type");

-- Index for finding unpaid credits by client
CREATE INDEX IF NOT EXISTS "idx_transaction_client_paid" ON "Transaction"("clientId", "isPaid", "type");

-- Index for sync queries
CREATE INDEX IF NOT EXISTS "idx_transaction_syncstatus_created" ON "Transaction"("syncStatus", "createdAt" DESC);

-- Index for admin stats - transactions by user + type + date
CREATE INDEX IF NOT EXISTS "idx_transaction_admin_stats" ON "Transaction"("userId", "type", "transactionDate" DESC) WHERE "deletedAt" IS NULL;

-- Index for client by user
CREATE INDEX IF NOT EXISTS "idx_client_user_active" ON "Client"("userId", "isActive");
