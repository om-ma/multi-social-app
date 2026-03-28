import Ecto.Query

now = DateTime.utc_now() |> DateTime.truncate(:second)
ago = fn seconds -> DateTime.add(now, -seconds, :second) end

alias SocialApp.Repo
alias SocialApp.Accounts.User
alias SocialApp.Content.{Post, Story, Like, Reel}
alias SocialApp.Messaging.{Conversation, ConversationMember, Message}
alias SocialApp.Social.{Follow, Notification}

# ── 30 Users ──
user_data = [
  %{
    username: "ahmad_rashidi",
    email: "ahmad@example.com",
    display_name: "Ahmad Al-Rashidi",
    bio: "Riyadh vibes. Tech & Culture.",
    location: "Riyadh, SA"
  },
  %{
    username: "layla.creates",
    email: "layla@example.com",
    display_name: "Layla Hassan",
    bio: "Artist & calligrapher. Arabic art meets digital.",
    location: "Jeddah, SA"
  },
  %{
    username: "omar.ksa",
    email: "omar@example.com",
    display_name: "Omar Khalid",
    bio: "Heritage explorer. Diriyah enthusiast.",
    location: "Diriyah, SA"
  },
  %{
    username: "nora_designs",
    email: "nora@example.com",
    display_name: "Nora Al-Fahad",
    bio: "Interior designer. Minimalist aesthetics.",
    location: "Dubai, UAE"
  },
  %{
    username: "khalid.beats",
    email: "khalid@example.com",
    display_name: "Khalid Ibrahim",
    bio: "Music producer. Blending Arabic & electronic.",
    location: "Riyadh, SA"
  },
  %{
    username: "sara.fitness",
    email: "sara@example.com",
    display_name: "Sara Al-Otaibi",
    bio: "Fitness coach. Healthy living advocate.",
    location: "Riyadh, SA"
  },
  %{
    username: "yousef.dev",
    email: "yousef@example.com",
    display_name: "Yousef Mansour",
    bio: "Full-stack developer. Building cool things.",
    location: "Amman, JO"
  },
  %{
    username: "fatima.reads",
    email: "fatima@example.com",
    display_name: "Fatima Al-Harbi",
    bio: "Book lover. Sharing reviews & recommendations.",
    location: "Doha, QA"
  },
  %{
    username: "hassan.photo",
    email: "hassan@example.com",
    display_name: "Hassan Nasser",
    bio: "Street photographer. Capturing moments.",
    location: "Cairo, EG"
  },
  %{
    username: "mona.cooks",
    email: "mona@example.com",
    display_name: "Mona Al-Salem",
    bio: "Home chef. Traditional recipes with a twist.",
    location: "Kuwait City, KW"
  },
  %{
    username: "tariq.travels",
    email: "tariq@example.com",
    display_name: "Tariq Al-Dosari",
    bio: "Travel blogger. Exploring the world.",
    location: "Riyadh, SA"
  },
  %{
    username: "reem.style",
    email: "reem@example.com",
    display_name: "Reem Al-Qahtani",
    bio: "Fashion & modest wear inspiration.",
    location: "Jeddah, SA"
  },
  %{
    username: "abdulaziz.tech",
    email: "abdulaziz@example.com",
    display_name: "Abdulaziz Khan",
    bio: "AI researcher. Tech enthusiast.",
    location: "Riyadh, SA"
  },
  %{
    username: "dina.wellness",
    email: "dina@example.com",
    display_name: "Dina Mahmoud",
    bio: "Wellness coach. Mind, body, soul.",
    location: "Beirut, LB"
  },
  %{
    username: "faisal.motors",
    email: "faisal@example.com",
    display_name: "Faisal Al-Rashid",
    bio: "Car enthusiast. Supercars & drift culture.",
    location: "Riyadh, SA"
  },
  %{
    username: "lina.art",
    email: "lina@example.com",
    display_name: "Lina Hamdan",
    bio: "Digital artist. NFT creator.",
    location: "Dubai, UAE"
  },
  %{
    username: "mohammed.eats",
    email: "mohammed@example.com",
    display_name: "Mohammed Al-Shehri",
    bio: "Food critic. Best spots in the Gulf.",
    location: "Bahrain"
  },
  %{
    username: "huda.teaches",
    email: "huda@example.com",
    display_name: "Huda Al-Mutairi",
    bio: "Teacher & education advocate.",
    location: "Riyadh, SA"
  },
  %{
    username: "sultan.games",
    email: "sultan@example.com",
    display_name: "Sultan Al-Ghamdi",
    bio: "Gamer & esports commentator.",
    location: "Riyadh, SA"
  },
  %{
    username: "nouf.writes",
    email: "nouf@example.com",
    display_name: "Nouf Al-Dawsari",
    bio: "Journalist. Writing about tech & society.",
    location: "Riyadh, SA"
  },
  %{
    username: "ali.builds",
    email: "ali@example.com",
    display_name: "Ali Hassan",
    bio: "Architect. Modern Arabian design.",
    location: "Muscat, OM"
  },
  %{
    username: "mariam.sings",
    email: "mariam@example.com",
    display_name: "Mariam Al-Balushi",
    bio: "Singer & songwriter. Arabic pop.",
    location: "Dubai, UAE"
  },
  %{
    username: "khaled.runs",
    email: "khaled@example.com",
    display_name: "Khaled Noor",
    bio: "Marathon runner. Ultra trail lover.",
    location: "Riyadh, SA"
  },
  %{
    username: "aisha.codes",
    email: "aisha@example.com",
    display_name: "Aisha Patel",
    bio: "Backend engineer. Elixir enthusiast.",
    location: "Abu Dhabi, UAE"
  },
  %{
    username: "hamad.films",
    email: "hamad@example.com",
    display_name: "Hamad Al-Thani",
    bio: "Filmmaker. Short films & documentaries.",
    location: "Doha, QA"
  },
  %{
    username: "salma.paints",
    email: "salma@example.com",
    display_name: "Salma Youssef",
    bio: "Watercolor artist. Nature scenes.",
    location: "Cairo, EG"
  },
  %{
    username: "badr.invests",
    email: "badr@example.com",
    display_name: "Badr Al-Subaie",
    bio: "Angel investor. Startup ecosystem.",
    location: "Riyadh, SA"
  },
  %{
    username: "dana.vlogs",
    email: "dana@example.com",
    display_name: "Dana Al-Anazi",
    bio: "Lifestyle vlogger. Daily Saudi life.",
    location: "Jeddah, SA"
  },
  %{
    username: "rashid.coaches",
    email: "rashid@example.com",
    display_name: "Rashid Omar",
    bio: "Football coach. Youth development.",
    location: "Riyadh, SA"
  },
  %{
    username: "zainab.gardens",
    email: "zainab@example.com",
    display_name: "Zainab Al-Hashimi",
    bio: "Urban gardener. Green spaces advocate.",
    location: "Manama, BH"
  }
]

users =
  Enum.map(user_data, fn data ->
    Repo.insert!(%User{
      username: data.username,
      email: data.email,
      display_name: data.display_name,
      hashed_password: Bcrypt.hash_pwd_salt("password123"),
      bio: data.bio,
      location: data.location
    })
  end)

IO.puts("Seeded #{length(users)} users")

# ── Posts ──
post_contents = [
  {"Riyadh Season 2025 is absolutely insane! The lights, the energy — nothing like it. Who's going tonight?",
   "image"},
  {"New artwork dropping tomorrow. Been working on this piece for 3 weeks. Arabic calligraphy meets digital art.",
   "image"},
  {"Old Diriyah at golden hour. The history here is unmatched.", "image"},
  {"Just finished redesigning a villa in Jumeirah. Minimalist Arabian style — clean lines, warm textures.",
   "image"},
  {"New track dropping Friday. Arabic beats mixed with electronic — you're not ready for this one.",
   "audio"},
  {"Morning workout complete! 5am club. No excuses.", nil},
  {"Just deployed a new feature using Phoenix LiveView. The developer experience is incredible.",
   nil},
  {"Currently reading 'The Forty Rules of Love'. Absolutely beautiful storytelling.", nil},
  {"Golden hour in the old quarter. The light hits different here.", "image"},
  {"Traditional kabsa recipe with a modern twist. Swipe for the full recipe!", "image"},
  {"Just landed in Bali. Two weeks of exploring ahead!", "image"},
  {"New collection preview. Modest fashion can be bold and beautiful.", "image"},
  {"The future of AI in the Middle East — my thoughts after attending LEAP 2025.", nil},
  {"Meditation changed my life. 10 minutes a day is all it takes.", nil},
  {"Took the new GT-R to the track today. Pure adrenaline.", "video"},
  {"My latest digital artwork inspired by Islamic geometry. Each pattern tells a story.",
   "image"},
  {"Best shawarma in Bahrain? I've found it. Thread incoming...", nil},
  {"Proud of my students who won the national science competition!", nil},
  {"Just hit Champion rank in Valorant. 500 hours later...", nil},
  {"My latest article on tech regulation in Saudi Arabia is live. Link in bio.", nil}
]

posts =
  Enum.with_index(post_contents)
  |> Enum.map(fn {{content, media_type}, idx} ->
    user = Enum.at(users, rem(idx, length(users)))
    hours_ago = :rand.uniform(72)

    Repo.insert!(%Post{
      user_id: user.id,
      content: content,
      media_type: media_type,
      media_url: if(media_type, do: "/images/sample_#{idx + 1}.jpg"),
      likes_count: :rand.uniform(5000),
      comments_count: :rand.uniform(500),
      score: :rand.uniform() * 100,
      inserted_at: ago.(hours_ago * 3600),
      updated_at: now
    })
  end)

IO.puts("Seeded #{length(posts)} posts")

# ── Likes (random likes on posts) ──
likes =
  for post <- Enum.take(posts, 10),
      liker <- Enum.take_random(users, :rand.uniform(5) + 2) do
    Repo.insert!(%Like{
      user_id: liker.id,
      post_id: post.id,
      inserted_at: now,
      updated_at: now
    })
  end

IO.puts("Seeded #{length(likes)} likes")

# ── Stories ──
stories =
  Enum.take_random(users, 8)
  |> Enum.map(fn user ->
    Repo.insert!(%Story{
      user_id: user.id,
      media_url: "/images/story_#{user.id}.jpg",
      expires_at: DateTime.add(now, 24 * 3600, :second) |> DateTime.truncate(:second),
      inserted_at: now,
      updated_at: now
    })
  end)

IO.puts("Seeded #{length(stories)} stories")

# ── Reels ──
reel_captions = [
  "Old Diriyah at golden hour. The history here is unmatched. #Riyadh #Saudi #Heritage",
  "POV: You just discovered the best hidden cafe in Jeddah",
  "Watch me create this calligraphy piece from scratch",
  "Morning routine that changed my life (not clickbait)",
  "The most underrated spot in Dubai. Trust me on this one.",
  "Making traditional Arabic coffee the old way",
  "This workout will destroy your legs (in a good way)",
  "Coding a full app in 24 hours challenge"
]

reels =
  Enum.with_index(reel_captions)
  |> Enum.map(fn {caption, idx} ->
    user = Enum.at(users, rem(idx, length(users)))

    Repo.insert!(%Reel{
      user_id: user.id,
      video_url: "/videos/reel_#{idx + 1}.mp4",
      thumbnail_url: "/images/reel_thumb_#{idx + 1}.jpg",
      caption: caption,
      views_count: :rand.uniform(100_000),
      likes_count: :rand.uniform(50_000),
      comments_count: :rand.uniform(2000),
      score: :rand.uniform() * 200,
      inserted_at: ago.(:rand.uniform(48) * 3600),
      updated_at: now
    })
  end)

IO.puts("Seeded #{length(reels)} reels")

# ── Follows (create a social graph) ──
follows =
  for follower <- Enum.take(users, 15),
      following <- Enum.take_random(users -- [follower], :rand.uniform(8) + 3) do
    Repo.insert!(%Follow{
      follower_id: follower.id,
      following_id: following.id,
      inserted_at: now,
      updated_at: now
    })
  end

IO.puts("Seeded #{length(follows)} follows")

# Update follower/following counts
for user <- users do
  follower_count = Repo.aggregate(from(f in Follow, where: f.following_id == ^user.id), :count)
  following_count = Repo.aggregate(from(f in Follow, where: f.follower_id == ^user.id), :count)
  post_count = Repo.aggregate(from(p in Post, where: p.user_id == ^user.id), :count)

  Repo.update_all(
    from(u in User, where: u.id == ^user.id),
    set: [
      followers_count: follower_count,
      following_count: following_count,
      posts_count: post_count
    ]
  )
end

IO.puts("Updated user counters")

# ── Conversations & Messages ──
# Create 5 DM conversations
dm_pairs = Enum.chunk_every(Enum.take_random(users, 10), 2)

conversations =
  Enum.map(dm_pairs, fn [user_a, user_b] ->
    conv =
      Repo.insert!(%Conversation{
        is_group: false,
        inserted_at: now,
        updated_at: now
      })

    Repo.insert!(%ConversationMember{
      conversation_id: conv.id,
      user_id: user_a.id,
      joined_at: now,
      inserted_at: now,
      updated_at: now
    })

    Repo.insert!(%ConversationMember{
      conversation_id: conv.id,
      user_id: user_b.id,
      joined_at: now,
      inserted_at: now,
      updated_at: now
    })

    messages = [
      "Hey! How are you?",
      "I'm good! Just saw your latest post, amazing work!",
      "Thanks! Working on something new. Will share soon.",
      "Can't wait to see it! Are you going to the event tonight?",
      "Yes definitely! See you there."
    ]

    Enum.with_index(messages)
    |> Enum.each(fn {body, idx} ->
      sender = if rem(idx, 2) == 0, do: user_a, else: user_b
      minutes_ago = (length(messages) - idx) * 15

      Repo.insert!(%Message{
        conversation_id: conv.id,
        sender_id: sender.id,
        body: body,
        inserted_at: ago.(minutes_ago * 60),
        updated_at: now
      })
    end)

    conv
  end)

# Create 1 group chat
group =
  Repo.insert!(%Conversation{
    is_group: true,
    name: "Riyadh Creators",
    inserted_at: now,
    updated_at: now
  })

group_members = Enum.take(users, 6)

Enum.each(group_members, fn user ->
  Repo.insert!(%ConversationMember{
    conversation_id: group.id,
    user_id: user.id,
    joined_at: now,
    inserted_at: now,
    updated_at: now
  })
end)

group_messages = [
  "Who's coming to the meetup on Friday?",
  "I'm in! What time?",
  "7 PM at the usual spot",
  "Perfect, I'll bring my camera",
  "Let's collab on something this time",
  "Great idea! I have some concepts ready"
]

Enum.with_index(group_messages)
|> Enum.each(fn {body, idx} ->
  sender = Enum.at(group_members, rem(idx, length(group_members)))
  minutes_ago = (length(group_messages) - idx) * 10

  Repo.insert!(%Message{
    conversation_id: group.id,
    sender_id: sender.id,
    body: body,
    inserted_at: ago.(minutes_ago * 60),
    updated_at: now
  })
end)

IO.puts("Seeded #{length(conversations) + 1} conversations with messages")

# ── Notifications ──
notifications =
  for user <- Enum.take(users, 10) do
    actor = Enum.random(users -- [user])
    type = Enum.random(["like", "follow", "comment"])

    Repo.insert!(%Notification{
      user_id: user.id,
      actor_id: actor.id,
      type: type,
      reference_id: if(type in ["like", "comment"], do: Enum.random(posts).id),
      inserted_at: ago.(:rand.uniform(24) * 3600),
      updated_at: now
    })
  end

IO.puts("Seeded #{length(notifications)} notifications")
IO.puts("\nSeeding complete!")
