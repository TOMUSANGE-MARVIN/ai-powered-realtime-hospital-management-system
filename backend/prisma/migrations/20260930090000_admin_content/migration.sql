-- AlterTable
ALTER TABLE `notification` ADD COLUMN `announcementId` VARCHAR(191) NULL;

-- AlterTable
ALTER TABLE `review` ADD COLUMN `hidden` BOOLEAN NOT NULL DEFAULT false,
    ADD COLUMN `hiddenAt` DATETIME(3) NULL,
    ADD COLUMN `hiddenReason` TEXT NULL;

-- CreateTable
CREATE TABLE `announcement` (
    `id` VARCHAR(191) NOT NULL,
    `title` VARCHAR(191) NOT NULL,
    `message` TEXT NOT NULL,
    `audience` VARCHAR(191) NOT NULL,
    `link` TEXT NULL,
    `sentCount` INTEGER NOT NULL DEFAULT 0,
    `sentById` VARCHAR(191) NOT NULL,
    `sentByName` VARCHAR(191) NOT NULL,
    `createdAt` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),

PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `blog_post` (
    `id` VARCHAR(191) NOT NULL,
    `slug` VARCHAR(191) NOT NULL,
    `title` VARCHAR(191) NOT NULL,
    `excerpt` TEXT NOT NULL,
    `content` LONGTEXT NOT NULL,
    `category` VARCHAR(191) NOT NULL,
    `image` TEXT NULL,
    `accent` VARCHAR(191) NOT NULL DEFAULT 'sky',
    `authorName` VARCHAR(191) NULL,
    `published` BOOLEAN NOT NULL DEFAULT false,
    `publishedAt` DATETIME(3) NULL,
    `createdAt` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    `updatedAt` DATETIME(3) NOT NULL,

UNIQUE INDEX `blog_post_slug_key`(`slug`),
    INDEX `blog_post_published_publishedAt_idx`(`published`, `publishedAt`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateIndex
CREATE INDEX `notification_announcementId_idx` ON `notification`(`announcementId`);


-- Seed the posts that used to live in frontend/app/lib/blogPosts.ts
INSERT INTO `blog_post` (`id`, `slug`, `title`, `excerpt`, `content`, `category`, `image`, `accent`, `authorName`, `published`, `publishedAt`, `createdAt`, `updatedAt`) VALUES
('seedpost01', 'managing-stress-before-it-manages-you', 'Managing stress before it manages you', 'A short daily walk can do more for your stress levels than an hour of scrolling. Here''s what the evidence actually says.', 'Stress isn''t just a feeling — it''s a measurable physiological response, and left unmanaged, it shows up in blood pressure readings, sleep quality, and immune function long before it shows up in how you feel day to day.

The good news is that the interventions with the strongest evidence behind them are also the simplest: 20–30 minutes of moderate movement most days, consistent sleep and wake times, and short breaks away from screens through the day. None of these require special equipment or a major schedule overhaul.

If you notice stress affecting your sleep, appetite, or mood for more than a couple of weeks, that''s worth bringing to a visit rather than waiting it out — early conversations are easier than late interventions.

Our Internal Medicine and Mental Health teams work together on exactly this kind of overlap, so a single visit can cover both the physical and emotional side of what you''re experiencing.', 'Wellness', 'https://images.unsplash.com/photo-1476480862126-209bfaa8edc8?w=800&q=80&auto=format&fit=crop', 'lime', 'Ask Musawo', true, '2026-05-24 09:00:00.000', '2026-05-24 09:00:00.000', '2026-05-24 09:00:00.000'),
('seedpost02', 'how-sleep-affects-your-recovery', 'How sleep affects your recovery', 'Recovery doesn''t happen in the clinic — it happens overnight. Here''s why sleep quality matters as much as any treatment plan.', 'Whatever you''re recovering from — surgery, an infection, or simply a demanding season of life — most of the actual repair work your body does happens while you sleep, not while you''re awake following a treatment plan.

During deep sleep, the body releases growth hormone, repairs tissue, and consolidates the immune response built up during the day. Consistently cutting sleep short doesn''t just leave you tired; it measurably slows healing and raises inflammation markers.

A few habits make an outsized difference: a consistent bedtime, a dark and cool room, and cutting caffeine after early afternoon. If you''re managing a chronic condition, ask your care team whether your medication timing could be adjusted to support better sleep rather than disrupt it.

If sleep problems persist despite good habits, it''s worth a conversation — poor sleep is sometimes a symptom rather than just an inconvenience.', 'Recovery', 'https://images.unsplash.com/photo-1541781774459-bb2af2f05b55?w=800&q=80&auto=format&fit=crop', 'amber', 'Ask Musawo', true, '2026-04-18 09:00:00.000', '2026-04-18 09:00:00.000', '2026-04-18 09:00:00.000'),
('seedpost03', 'nutrition-tips-for-faster-healing', 'Nutrition tips for faster healing', 'What you eat after an illness or procedure has a direct, measurable effect on how quickly you get back on your feet.', 'Protein is the nutrient most directly tied to tissue repair, and it''s also the one people cut back on when they''re not feeling well. Aim for a source of protein at every meal during recovery — eggs, beans, fish, or lean meat all work.

Vitamin C and zinc both play specific roles in wound healing and immune function. A varied diet with vegetables, fruit, and whole grains usually covers this without needing supplements, though your care team may recommend otherwise for specific conditions.

Hydration is easy to underestimate. Many recovery symptoms — fatigue, headache, constipation — are worsened by mild dehydration that''s easy to miss when you''re not feeling like yourself.

If you''re managing a condition with dietary restrictions, our nutrition team can build a plan that fits your treatment rather than working against it.', 'Nutrition', 'https://images.unsplash.com/photo-1498837167922-ddd27525d352?w=800&q=80&auto=format&fit=crop', 'orange', 'Ask Musawo', true, '2026-03-08 09:00:00.000', '2026-03-08 09:00:00.000', '2026-03-08 09:00:00.000'),
('seedpost04', 'why-regular-checkups-matter', 'Why regular checkups matter more than you think', 'Most serious conditions are far easier to treat when caught early — which only happens if you''re actually being screened.', 'It''s easy to skip a checkup when nothing feels wrong. But conditions like high blood pressure, early diabetes, and several cancers are most treatable precisely because they show no symptoms in their earliest stages — the only way to catch them is to look.

A standard annual visit typically covers blood pressure, weight trends, basic bloodwork, and a conversation about anything that''s changed since your last visit. It''s a short appointment that consistently pays for itself in problems avoided.

Your risk factors — family history, age, lifestyle — determine which screenings matter most for you specifically. That''s a conversation worth having directly with your physician rather than guessing from a checklist online.

Booking a routine checkup takes a few minutes through our patient portal, and most visits are covered under standard insurance plans.', 'Preventive Care', 'https://images.unsplash.com/photo-1631815588090-d4bfec5b1ccb?w=800&q=80&auto=format&fit=crop', 'sky', 'Ask Musawo', true, '2026-02-22 09:00:00.000', '2026-02-22 09:00:00.000', '2026-02-22 09:00:00.000'),
('seedpost05', 'mindfulness-and-the-mind-body-connection', 'Mindfulness and the mind-body connection', 'The link between mental state and physical health isn''t just anecdotal — it shows up clearly in clinical outcomes.', 'Patients managing chronic pain, heart conditions, and autoimmune disorders consistently show better outcomes when mental health is treated as part of the care plan rather than a separate concern.

Mindfulness practice — even just 10 minutes of focused breathing a day — has been shown to lower cortisol levels and improve heart rate variability, both of which are markers of how well your body handles stress over time.

This isn''t about replacing medical treatment with meditation. It''s about recognizing that a calmer nervous system responds better to the treatment you''re already receiving.

If chronic stress or anxiety is part of what you''re dealing with, say so at your next visit — it changes how we think about your care plan, not just your mood.', 'Mental Health', 'https://images.unsplash.com/photo-1506126613408-eca07ce68773?w=800&q=80&auto=format&fit=crop', 'violet', 'Ask Musawo', true, '2026-01-30 09:00:00.000', '2026-01-30 09:00:00.000', '2026-01-30 09:00:00.000'),
('seedpost06', 'understanding-your-brain-memory-and-aging', 'Understanding your brain: memory and aging', 'Some memory changes are a normal part of aging. Others are worth a conversation. Here''s how to tell the difference.', 'Occasionally forgetting a name or misplacing keys is a normal part of an aging brain — attention and processing speed naturally shift over time. This is different from memory loss that interferes with daily life.

Warning signs worth discussing with a doctor include: difficulty following familiar routines, repeating questions shortly after asking them, or noticeable changes in judgment or mood alongside memory changes.

The evidence on prevention is encouraging: regular physical activity, social engagement, and managing cardiovascular risk factors like blood pressure all measurably support long-term brain health.

Early evaluation matters — many causes of memory changes are treatable, and even for those that aren''t, early diagnosis gives you and your family more time to plan.', 'Neurology', 'https://images.unsplash.com/photo-1559757148-5c350d0d3c56?w=800&q=80&auto=format&fit=crop', 'rose', 'Ask Musawo', true, '2026-01-12 09:00:00.000', '2026-01-12 09:00:00.000', '2026-01-12 09:00:00.000');
