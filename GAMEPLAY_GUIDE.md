# 🎮 SKILL CHAMPS - COMPLETE MVP GAMEPLAY GUIDE

## 🎯 GAME OBJECTIVE

Compete against an AI opponent in dynamic, real-time races where:
- **Your stats matter** - Higher skills = faster racing
- **Races are unpredictable** - Overtakes can happen at any moment
- **Winners are determined ONLY at the end** - No pre-decided outcomes
- **Every race feels different** - Slight randomness for tension and excitement

---

## 🏃 HOW THE GAME WORKS

### 1️⃣ GAME LOOP

```
┌─────────────────────────────────────┐
│  Main Menu / Home Screen            │
│  • View stats (Level, XP, Coins)    │
│  • Check current power-up            │
└────────────┬────────────────────────┘
             │
             ↓
┌─────────────────────────────────────┐
│  Training/Upgrade Skills            │
│  • 🏃 Speed (20 coins per upgrade)  │
│  • ⛰️ Climb (20 coins per upgrade)   │
│  • 🏊 Swim (20 coins per upgrade)    │
│  • ✈️ Fly (20 coins per upgrade)     │
│  • Max level: 30 per stat            │
└────────────┬────────────────────────┘
             │
             ↓
┌─────────────────────────────────────┐
│  Start Race 🎮                      │
│  • AI opponent spawns with scaled   │
│    stats based on your level        │
│  • Race animated in real-time       │
│  • 4 segments: Run/Climb/Swim/Fly  │
│  • Each segment 1.5 seconds         │
│  • Total race: 6 seconds            │
└────────────┬────────────────────────┘
             │
             ↓
┌─────────────────────────────────────┐
│  Race Visualization                 │
│  • Live segment indicator           │
│  • Real-time stat comparison        │
│  • Player position on track         │
│  • Race margin display              │
│  • Leader highlight (gold glow)     │
│  • Overtake haptic feedback         │
└────────────┬────────────────────────┘
             │
             ↓
┌─────────────────────────────────────┐
│  Results Screen 🏆                  │
│  WIN (+30 coins, +50 XP)            │
│  LOSS (+10 XP, +5 coins)            │
│  40% chance for chest reward        │
└────────────┬────────────────────────┘
             │
             └─→ (Return to Home Screen)
```

---

## 🏁 THE 4-STAGE RACE SYSTEM

Each race has **4 distinct segments**, each using a different stat:

### Stage 1: 🏃 RUN (Speed Stat)
- Duration: 1.5 seconds
- Uses: **Speed stat**
- The faster your speed → the faster you move
- High variance for tension

### Stage 2: ⛰️ CLIMB (Climb Stat)
- Duration: 1.5 seconds  
- Uses: **Climb stat**
- The higher your climb → the faster you move
- Overtak es can happen!

### Stage 3: 🏊 SWIM (Swim Stat)
- Duration: 1.5 seconds
- Uses: **Swim stat**
- Strategy: If opponent weak in swim, overtake now!
- Lead changes visible with haptic feedback

### Stage 4: ✈️ FLY (Fly Stat)
- Duration: 1.5 seconds
- Uses: **Fly stat**
- Final stage - momentum matters
- Winner determined here

**Total Race Time: 6 seconds**

---

## 💰 PROGRESSION SYSTEM

### Rewards
| Event | Coins | XP | Chest? |
|-------|-------|----|----|
| **Win** | +30 | +50 | 40% chance |
| **Loss** | +5 | +10 | No |

### Leveling
- XP requirements scale per level
- Each level increases AI difficulty
- Higher level = stronger opponents

### Skill Upgrades
- **Cost**: 20 coins per upgrade
- **Max Level**: 30 per stat
- **Effect**: +1 to stat value
- Direct impact on race performance

---

## 🎮 REAL-TIME RACE ENGINE

### How Velocity is Calculated

```
For each stat, the velocity formula is:
1. Get player's stat for current stage (e.g., Speed)
2. Apply power-up bonus if available
3. Calculate: statRatio = stat / 10.0
4. Apply: baseVel = 0.5 × statRatio
5. Add randomness: ±0.15 variance
6. Clamp to reasonable range: 0.05-2.0
```

### Whatthis Means
- **Weak stat (5)** → velocity ≈ 0.25 (slow)
- **Average stat (10)** → velocity ≈ 0.5 (normal)
- **Strong stat (20)** → velocity ≈ 1.0 (fast)
- **Max stat (30)** → velocity ≈ 1.5 (very fast)

### Slight Randomness
- Each tick, velocity varies ±15%
- Creates tension even with stat diff
- Close races feel competitive
- Victories feel earned not predetermined

---

## 🎯 OVERTAKES & DYNAMIC GAMEPLAY

### Live Lead Changes
The race engine detects when a player overtakes:
- **Margin Detection**: Checked every 16ms (60 FPS)
- **Haptic Feedback**: Medium impact when overtake detected
- **Visual Feedback**: Leader highlighted in gold glow
- **Tension Building**: Makes races exciting!

### Example Scenario
1. Player has 12 speed, opponent has 8 speed
2. **Stage 1 (Run)**: Player pulls ahead (likely)
3. **Stage 2 (Climb)**: Opponent has 15 climb vs player's 10
4. **Opponent overtakes** → Haptic feedback + visual glow
5. **Stage 3 (Swim)**: Player has 14 swim vs opponent's 9
6. **Player overtakes back** → Another glow + haptic
7. **Stage 4 (Fly)**: Whoever's ahead at finish line WINS

---

## 📊 STAT COMPARISON DURING RACE

During each stage, the UI shows:
- **Current stage** indicator (e.g., "🏃 Run")
- **Your stat** for that stage
- **Opponent's stat** for that stage
- **Race margin** (e.g., "5.3% ahead")
- **Direction indicator** (▲ winning / ▼ losing)

This lets you:
- See which stats you're strong/weak in
- Understand why you're winning/losing each segment
- Plan future training accordingly

---

## 🧠 STRATEGY TIPS

### Training Priority
1. **Identify your weakest stat**
   - Win races to earn coins
   - Use coins to upgrade weak stats

2. **Build balanced growth**
   - All 4 stats contribute equally
   - No single stat dominates
   - Need a total power approach

3. **Level scaling**
   - As you level, opponents level too
   - Higher AI = harder matches
   - Keep stats balanced!

### During Races
1. **Watch the stat comparison**
   - See where you're strong
   - See where opponent could catch up

2. **Anticipate overtakes**
   - If opponent strong in next stage, prepare
   - Vice versa for your advantages

3. **Understand the margin**
   - Close races (5-15% margin) are tense
   - Leads can change any moment
   - Nothing is decided until finish

---

## ⚡ POWER-UP SYSTEM

### Available Power-Ups
1. **Speed Boost** ⚡ → +2-3 speed in Run stage
2. **Climb Boost** 🧗 → +2-3 climb in Climb stage
3. **Swim Boost** 🏊 → +2-3 swim in Swim stage
4. **Fly Boost** ✈️ → +2-3 fly in Fly stage
5. **Shield** 🛡️ → +1 to all stats (all stages)

### Usage
- Select one power-up per race
- Applied ONLY to human player (AI never gets powerups)
- Stacks with your stat training
- Gives strategic advantage

---

## 🎁 CHEST REWARD SYSTEM

### Chest Types
| Type | Unlock Time | Base Reward |
|------|-------------|------------|
| **Silver** ⚪ | 30 seconds | 10-20 coins |
| **Gold** 🟡 | 2 minutes | 25-50 coins |
| **Epic** 🟣 | 5 minutes | 50-100 coins |

### Opening Chests
1. **Wait** for unlock timer
2. **Tap** the chest to open
3. **Animation** plays with celebration
4. **Coins added** to your account
5. **Slot freed** for new chest

### Chest Drop Rate
- 40% chance per win (if you win)
- Max 3 chests in inventory
- Incentivizes winning!

---

## 📈 PROGRESSION MILESTONES

```
Level 1  → AI: Speed 7, Climb 7, Swim 7, Fly 7
Level 2  → AI: Speed 8, Climb 8, Swim 8, Fly 8  
Level 5  → AI: Speed 9, Climb 9, Swim 9, Fly 9
Level 10 → AI: Speed 12, Climb 12, Swim 12, Fly 12
```

Your training keeps pace with AI scaling.

---

## 🚀 COMPLETE FEATURES

✅ **Real-time race engine** - Tick-based 60 FPS simulation
✅ **Dynamic outcomes** - Winner determined ONLY at end
✅ **4-stage racing** - Each uses different stat
✅ **Overtake detection** - Live lead changes with feedback
✅ **Training system** - Upgrade all 4 stats
✅ **AI scaling** - Difficulty increases with level
✅ **Progression** - XP, levels, rewards
✅ **Chest system** - Rarity-based coin rewards
✅ **Power-ups** - Strategic racing bonuses
✅ **Real game feel** - Haptic feedback, animations, transitions

---

## 🎮 HOW TO PLAY (QUICK START)

### First Game
1. Open app → You start at Level 1
2. You have: 50 coins, stats (Speed 10, Climb 8, Swim 6, Fly 7)
3. Tap "Start Match" to begin racing
4. Watch your stats vs opponent
5. **Win** → +30 coins! Upgrade skills!
6. **Lose** → Try again, you got +10 XP

### Winning Strategy
1. **Race 1-2 times** to get 30+ coins
2. **Upgrade weakest skill** to Level 11
3. **Repeat** until all stats Level 15
4. **Now you're stronger** than starting AI
5. **Win more races** and keep upgrading!

---

## 🏆 GAME FEEL & RESPONSIVENESS

- **Race duration**: ~6 seconds (perfect for mobile)
- **Result feedback**: Instant (2-3 seconds)
- **Total round**: ~10-15 seconds (snappy, engaging)
- **Haptic feedback**: Vibration on key moments
- **Animations**: Smooth 60 FPS throughout
- **Stats visual**: Real-time updates every frame

---

## 🎨 UI/UX HIGHLIGHTS

✨ **Gradient backgrounds** for visual appeal
✨ **Color-coded stats** (Orange/Green/Blue/Purple)
✨ **Segment indicators** with emojis
✨ **Leader glow** effect during races
✨ **Real-time stat bars** showing comparison
✨ **Winner celebration** animation
✨ **Skill upgrade feedback** with sparkles
✨ **Progress bars** for leveling/chests

---

## 🏁 FINAL THOUGHTS

This is a **fully playable, polished MVP** that:
- ✅ Feels like a real mobile game
- ✅ Has meaningful progression
- ✅ Features competitive, dynamic racing
- ✅ Rewards player skill (training stats matters!)
- ✅ Is ready for store submission
- ✅ Can be monetized (premium skins, power-ups, ad coins)
- ✅ Can be expanded (multiplayer, tournaments, leagues)

**Enjoy the game and keep training your skills!** 🎮🏆
