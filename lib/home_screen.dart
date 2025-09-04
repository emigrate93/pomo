import 'dart:async';
import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  /// ───────── 설정값 ─────────
  static const List<int> presets = [15, 20, 25, 30, 35]; // 분 프리셋
  static const int breakMinutes = 5;

  /// ───────── 상태값 ─────────
  int selectedMinutes = 25;
  int baseSeconds = 25 * 60; // 선택 프리셋의 초
  int totalSeconds = 25 * 60; // 화면 표시 남은 초
  int breakSeconds = breakMinutes * 60; // 휴식 타이머
  bool isRunning = false;
  bool isBreak = false; // 휴식 모드 여부
  int totalPomodoros = 0; // 0/4
  int totalGoals = 0; // 0/12
  Timer? timer;

  /// 타이머 틱
  void onTick(Timer t) {
    if (totalSeconds == 0) {
      t.cancel();
      setState(() {
        isRunning = false;

        if (isBreak) {
          // 휴식 종료 → 작업 타이머 준비
          isBreak = false;
          totalSeconds = baseSeconds;
        } else {
          // 작업 종료 → 사이클 +1
          totalPomodoros += 1;

          // 4사이클 완료 → 라운드 +1, 휴식 모드 전환
          if (totalPomodoros == 4) {
            totalGoals += 1;
            totalPomodoros = 0;
            isBreak = true;
            totalSeconds = breakSeconds;
          } else {
            totalSeconds = baseSeconds;
          }
        }
      });
    } else {
      setState(() => totalSeconds -= 1);
    }
  }

  void onStartPressed() {
    if (isRunning) return;
    timer = Timer.periodic(const Duration(seconds: 1), onTick);
    setState(() => isRunning = true);
  }

  void onPausePressed() {
    timer?.cancel();
    setState(() => isRunning = false);
  }

  void onReset() {
    timer?.cancel();
    setState(() {
      isRunning = false;
      isBreak = false;
      baseSeconds = selectedMinutes * 60;
      totalSeconds = baseSeconds;
      totalPomodoros = 0;
      totalGoals = 0;
    });
  }

  /// 프리셋 선택 시: 진행 중이면 중지하고 모두 초기화(ROUND/GOAL 포함)
  void onSelectMinutes(int m) {
    timer?.cancel();
    setState(() {
      selectedMinutes = m;
      baseSeconds = m * 60;
      totalSeconds = baseSeconds;
      isRunning = false;
      isBreak = false;
      totalPomodoros = 0; // 0/4
      totalGoals = 0; // 0/12
    });
  }

  /// mm:ss 분리 (정적 카드 표시에 사용)
  String get mm => (totalSeconds ~/ 60).toString().padLeft(2, '0');
  String get ss => (totalSeconds % 60).toString().padLeft(2, '0');

  @override
  Widget build(BuildContext context) {
    final cardColor = Theme.of(context).cardColor; // 보통 흰색
    final textColor = Theme.of(context).textTheme.displayLarge!.color!; // 보통 흰색
    final faded = textColor.withOpacity(0.6);
    final red = Theme.of(context).scaffoldBackgroundColor; // 배경 레드

    // 선택 인덱스 & 거리 기반 투명도 함수
    final selectedIndex = presets.indexOf(selectedMinutes);
    double opacityFor(int index) {
      final d = (index - selectedIndex).abs();
      if (d == 0) return 1.0;
      if (d == 1) return 0.70;
      if (d == 2) return 0.45;
      return 0.25;
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          // ───── 타이머 표시(정적 카드 2개) ─────
          Flexible(
            flex: 1,
            child: Container(
              alignment: Alignment.bottomCenter,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _timeCard(mm, fg: red, bg: Colors.white),
                  const SizedBox(width: 16),
                  Text(
                    ':',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.95),
                      fontSize: 42,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(width: 16),
                  _timeCard(ss, fg: red, bg: Colors.white),
                ],
              ),
            ),
          ),

          // ───── 컨트롤 & 시간 프리셋 ─────
          Flexible(
            flex: 2,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    iconSize: 98,
                    color: cardColor,
                    onPressed: isRunning ? onPausePressed : onStartPressed,
                    icon: Icon(
                      isRunning
                          ? Icons.pause_circle_outline
                          : Icons.play_circle_outline,
                    ),
                  ),
                  const SizedBox(height: 20),
                  IconButton(
                    iconSize: 30,
                    color: cardColor,
                    onPressed: onReset,
                    icon: const Icon(Icons.refresh_outlined),
                  ),
                  const SizedBox(height: 24),

                  // ─── 시간 프리셋 선택(가로 스크롤, 거리별 투명/크기) ───
                  SizedBox(
                    height: 64, // 스크롤 영역을 키워 존재감↑
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Row(
                        children: List.generate(presets.length, (i) {
                          final m = presets[i];
                          final selected = i == selectedIndex;
                          final o = opacityFor(i); // 0.25 ~ 1.0

                          // 크기/색상 세팅 (선택됨이 더 크고 선명)
                          final double w = selected ? 88 : 72;
                          final double h = selected ? 52 : 48;
                          final Color border = Colors.white
                              .withOpacity(selected ? 1.0 : 0.45 * o + 0.20);
                          final Color fill = selected
                              ? Colors.white
                              : Colors.white.withOpacity(0.10 * o + 0.05);
                          final Color label = selected
                              ? red
                              : Colors.white.withOpacity(0.85 * o);

                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              curve: Curves.easeOut,
                              width: w,
                              height: h,
                              decoration: BoxDecoration(
                                color: fill,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                    color: border, width: selected ? 1.8 : 1.4),
                                boxShadow: selected
                                    ? [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.12),
                                          blurRadius: 10,
                                          offset: const Offset(0, 4),
                                        ),
                                      ]
                                    : [],
                              ),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: () => onSelectMinutes(m),
                                child: Center(
                                  child: Text(
                                    '$m',
                                    style: TextStyle(
                                      color: label,
                                      fontSize: selected ? 18 : 16,
                                      fontWeight: selected
                                          ? FontWeight.w800
                                          : FontWeight.w700,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ───── 하단 카드: ROUND / GOAL ─────
          Flexible(
            flex: 1,
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(50),
                        topRight: Radius.circular(50),
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // LEFT: ROUND (사이클)
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '$totalPomodoros/4',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w700,
                                color: faded,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'ROUND',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.0,
                                color: textColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 30),
                        // RIGHT: GOAL (라운드)
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '$totalGoals/12',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w700,
                                color: faded,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'GOAL',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.0,
                                color: textColor,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 정적 시간 카드(분/초)
  Widget _timeCard(String value, {required Color fg, required Color bg}) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 110,
          height: 120,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.10),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Center(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.w800,
                color: fg, // 레드
                letterSpacing: 1,
              ),
            ),
          ),
        ),
        // 상단 탭 모양(옵션: 카드 느낌 살리기)
        Positioned(
          top: -8,
          left: 18,
          right: 18,
          child: Container(
            height: 14,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.95),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(6)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
