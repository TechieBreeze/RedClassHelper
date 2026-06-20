// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'quiz_session_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$QuizSessionState {

 String get bankId; ReviewMode get mode; List<Question> get questions; int get currentIndex; List<AnswerRecord> get answers; DateTime get startTime; QuizStatus get status; String? get bankName; int? get elapsedSeconds; int? get totalQuestions; int? get correctCount; int? get wrongCount; int? get newlyWrongCount; int? get newlyMasteredCount;
/// Create a copy of QuizSessionState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$QuizSessionStateCopyWith<QuizSessionState> get copyWith => _$QuizSessionStateCopyWithImpl<QuizSessionState>(this as QuizSessionState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is QuizSessionState&&(identical(other.bankId, bankId) || other.bankId == bankId)&&(identical(other.mode, mode) || other.mode == mode)&&const DeepCollectionEquality().equals(other.questions, questions)&&(identical(other.currentIndex, currentIndex) || other.currentIndex == currentIndex)&&const DeepCollectionEquality().equals(other.answers, answers)&&(identical(other.startTime, startTime) || other.startTime == startTime)&&(identical(other.status, status) || other.status == status)&&(identical(other.bankName, bankName) || other.bankName == bankName)&&(identical(other.elapsedSeconds, elapsedSeconds) || other.elapsedSeconds == elapsedSeconds)&&(identical(other.totalQuestions, totalQuestions) || other.totalQuestions == totalQuestions)&&(identical(other.correctCount, correctCount) || other.correctCount == correctCount)&&(identical(other.wrongCount, wrongCount) || other.wrongCount == wrongCount)&&(identical(other.newlyWrongCount, newlyWrongCount) || other.newlyWrongCount == newlyWrongCount)&&(identical(other.newlyMasteredCount, newlyMasteredCount) || other.newlyMasteredCount == newlyMasteredCount));
}


@override
int get hashCode => Object.hash(runtimeType,bankId,mode,const DeepCollectionEquality().hash(questions),currentIndex,const DeepCollectionEquality().hash(answers),startTime,status,bankName,elapsedSeconds,totalQuestions,correctCount,wrongCount,newlyWrongCount,newlyMasteredCount);

@override
String toString() {
  return 'QuizSessionState(bankId: $bankId, mode: $mode, questions: $questions, currentIndex: $currentIndex, answers: $answers, startTime: $startTime, status: $status, bankName: $bankName, elapsedSeconds: $elapsedSeconds, totalQuestions: $totalQuestions, correctCount: $correctCount, wrongCount: $wrongCount, newlyWrongCount: $newlyWrongCount, newlyMasteredCount: $newlyMasteredCount)';
}


}

/// @nodoc
abstract mixin class $QuizSessionStateCopyWith<$Res>  {
  factory $QuizSessionStateCopyWith(QuizSessionState value, $Res Function(QuizSessionState) _then) = _$QuizSessionStateCopyWithImpl;
@useResult
$Res call({
 String bankId, ReviewMode mode, List<Question> questions, int currentIndex, List<AnswerRecord> answers, DateTime startTime, QuizStatus status, String? bankName, int? elapsedSeconds, int? totalQuestions, int? correctCount, int? wrongCount, int? newlyWrongCount, int? newlyMasteredCount
});




}
/// @nodoc
class _$QuizSessionStateCopyWithImpl<$Res>
    implements $QuizSessionStateCopyWith<$Res> {
  _$QuizSessionStateCopyWithImpl(this._self, this._then);

  final QuizSessionState _self;
  final $Res Function(QuizSessionState) _then;

/// Create a copy of QuizSessionState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? bankId = null,Object? mode = null,Object? questions = null,Object? currentIndex = null,Object? answers = null,Object? startTime = null,Object? status = null,Object? bankName = freezed,Object? elapsedSeconds = freezed,Object? totalQuestions = freezed,Object? correctCount = freezed,Object? wrongCount = freezed,Object? newlyWrongCount = freezed,Object? newlyMasteredCount = freezed,}) {
  return _then(_self.copyWith(
bankId: null == bankId ? _self.bankId : bankId // ignore: cast_nullable_to_non_nullable
as String,mode: null == mode ? _self.mode : mode // ignore: cast_nullable_to_non_nullable
as ReviewMode,questions: null == questions ? _self.questions : questions // ignore: cast_nullable_to_non_nullable
as List<Question>,currentIndex: null == currentIndex ? _self.currentIndex : currentIndex // ignore: cast_nullable_to_non_nullable
as int,answers: null == answers ? _self.answers : answers // ignore: cast_nullable_to_non_nullable
as List<AnswerRecord>,startTime: null == startTime ? _self.startTime : startTime // ignore: cast_nullable_to_non_nullable
as DateTime,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as QuizStatus,bankName: freezed == bankName ? _self.bankName : bankName // ignore: cast_nullable_to_non_nullable
as String?,elapsedSeconds: freezed == elapsedSeconds ? _self.elapsedSeconds : elapsedSeconds // ignore: cast_nullable_to_non_nullable
as int?,totalQuestions: freezed == totalQuestions ? _self.totalQuestions : totalQuestions // ignore: cast_nullable_to_non_nullable
as int?,correctCount: freezed == correctCount ? _self.correctCount : correctCount // ignore: cast_nullable_to_non_nullable
as int?,wrongCount: freezed == wrongCount ? _self.wrongCount : wrongCount // ignore: cast_nullable_to_non_nullable
as int?,newlyWrongCount: freezed == newlyWrongCount ? _self.newlyWrongCount : newlyWrongCount // ignore: cast_nullable_to_non_nullable
as int?,newlyMasteredCount: freezed == newlyMasteredCount ? _self.newlyMasteredCount : newlyMasteredCount // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

}



/// @nodoc


class _QuizSessionState extends QuizSessionState {
  const _QuizSessionState({required this.bankId, required this.mode, required final  List<Question> questions, this.currentIndex = 0, final  List<AnswerRecord> answers = const [], required this.startTime, this.status = QuizStatus.idle, this.bankName, this.elapsedSeconds, this.totalQuestions, this.correctCount, this.wrongCount, this.newlyWrongCount, this.newlyMasteredCount}): _questions = questions,_answers = answers,super._();
  

@override final  String bankId;
@override final  ReviewMode mode;
 final  List<Question> _questions;
@override List<Question> get questions {
  if (_questions is EqualUnmodifiableListView) return _questions;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_questions);
}

@override@JsonKey() final  int currentIndex;
 final  List<AnswerRecord> _answers;
@override@JsonKey() List<AnswerRecord> get answers {
  if (_answers is EqualUnmodifiableListView) return _answers;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_answers);
}

@override final  DateTime startTime;
@override@JsonKey() final  QuizStatus status;
@override final  String? bankName;
@override final  int? elapsedSeconds;
@override final  int? totalQuestions;
@override final  int? correctCount;
@override final  int? wrongCount;
@override final  int? newlyWrongCount;
@override final  int? newlyMasteredCount;

/// Create a copy of QuizSessionState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$QuizSessionStateCopyWith<_QuizSessionState> get copyWith => __$QuizSessionStateCopyWithImpl<_QuizSessionState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _QuizSessionState&&(identical(other.bankId, bankId) || other.bankId == bankId)&&(identical(other.mode, mode) || other.mode == mode)&&const DeepCollectionEquality().equals(other._questions, _questions)&&(identical(other.currentIndex, currentIndex) || other.currentIndex == currentIndex)&&const DeepCollectionEquality().equals(other._answers, _answers)&&(identical(other.startTime, startTime) || other.startTime == startTime)&&(identical(other.status, status) || other.status == status)&&(identical(other.bankName, bankName) || other.bankName == bankName)&&(identical(other.elapsedSeconds, elapsedSeconds) || other.elapsedSeconds == elapsedSeconds)&&(identical(other.totalQuestions, totalQuestions) || other.totalQuestions == totalQuestions)&&(identical(other.correctCount, correctCount) || other.correctCount == correctCount)&&(identical(other.wrongCount, wrongCount) || other.wrongCount == wrongCount)&&(identical(other.newlyWrongCount, newlyWrongCount) || other.newlyWrongCount == newlyWrongCount)&&(identical(other.newlyMasteredCount, newlyMasteredCount) || other.newlyMasteredCount == newlyMasteredCount));
}


@override
int get hashCode => Object.hash(runtimeType,bankId,mode,const DeepCollectionEquality().hash(_questions),currentIndex,const DeepCollectionEquality().hash(_answers),startTime,status,bankName,elapsedSeconds,totalQuestions,correctCount,wrongCount,newlyWrongCount,newlyMasteredCount);

@override
String toString() {
  return 'QuizSessionState(bankId: $bankId, mode: $mode, questions: $questions, currentIndex: $currentIndex, answers: $answers, startTime: $startTime, status: $status, bankName: $bankName, elapsedSeconds: $elapsedSeconds, totalQuestions: $totalQuestions, correctCount: $correctCount, wrongCount: $wrongCount, newlyWrongCount: $newlyWrongCount, newlyMasteredCount: $newlyMasteredCount)';
}


}

/// @nodoc
abstract mixin class _$QuizSessionStateCopyWith<$Res> implements $QuizSessionStateCopyWith<$Res> {
  factory _$QuizSessionStateCopyWith(_QuizSessionState value, $Res Function(_QuizSessionState) _then) = __$QuizSessionStateCopyWithImpl;
@override @useResult
$Res call({
 String bankId, ReviewMode mode, List<Question> questions, int currentIndex, List<AnswerRecord> answers, DateTime startTime, QuizStatus status, String? bankName, int? elapsedSeconds, int? totalQuestions, int? correctCount, int? wrongCount, int? newlyWrongCount, int? newlyMasteredCount
});




}
/// @nodoc
class __$QuizSessionStateCopyWithImpl<$Res>
    implements _$QuizSessionStateCopyWith<$Res> {
  __$QuizSessionStateCopyWithImpl(this._self, this._then);

  final _QuizSessionState _self;
  final $Res Function(_QuizSessionState) _then;

/// Create a copy of QuizSessionState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? bankId = null,Object? mode = null,Object? questions = null,Object? currentIndex = null,Object? answers = null,Object? startTime = null,Object? status = null,Object? bankName = freezed,Object? elapsedSeconds = freezed,Object? totalQuestions = freezed,Object? correctCount = freezed,Object? wrongCount = freezed,Object? newlyWrongCount = freezed,Object? newlyMasteredCount = freezed,}) {
  return _then(_QuizSessionState(
bankId: null == bankId ? _self.bankId : bankId // ignore: cast_nullable_to_non_nullable
as String,mode: null == mode ? _self.mode : mode // ignore: cast_nullable_to_non_nullable
as ReviewMode,questions: null == questions ? _self._questions : questions // ignore: cast_nullable_to_non_nullable
as List<Question>,currentIndex: null == currentIndex ? _self.currentIndex : currentIndex // ignore: cast_nullable_to_non_nullable
as int,answers: null == answers ? _self._answers : answers // ignore: cast_nullable_to_non_nullable
as List<AnswerRecord>,startTime: null == startTime ? _self.startTime : startTime // ignore: cast_nullable_to_non_nullable
as DateTime,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as QuizStatus,bankName: freezed == bankName ? _self.bankName : bankName // ignore: cast_nullable_to_non_nullable
as String?,elapsedSeconds: freezed == elapsedSeconds ? _self.elapsedSeconds : elapsedSeconds // ignore: cast_nullable_to_non_nullable
as int?,totalQuestions: freezed == totalQuestions ? _self.totalQuestions : totalQuestions // ignore: cast_nullable_to_non_nullable
as int?,correctCount: freezed == correctCount ? _self.correctCount : correctCount // ignore: cast_nullable_to_non_nullable
as int?,wrongCount: freezed == wrongCount ? _self.wrongCount : wrongCount // ignore: cast_nullable_to_non_nullable
as int?,newlyWrongCount: freezed == newlyWrongCount ? _self.newlyWrongCount : newlyWrongCount // ignore: cast_nullable_to_non_nullable
as int?,newlyMasteredCount: freezed == newlyMasteredCount ? _self.newlyMasteredCount : newlyMasteredCount // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}

/// @nodoc
mixin _$AnswerRecord {

 String get questionId; List<String> get givenAnswer; bool get isCorrect; int get elapsedMs;
/// Create a copy of AnswerRecord
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AnswerRecordCopyWith<AnswerRecord> get copyWith => _$AnswerRecordCopyWithImpl<AnswerRecord>(this as AnswerRecord, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AnswerRecord&&(identical(other.questionId, questionId) || other.questionId == questionId)&&const DeepCollectionEquality().equals(other.givenAnswer, givenAnswer)&&(identical(other.isCorrect, isCorrect) || other.isCorrect == isCorrect)&&(identical(other.elapsedMs, elapsedMs) || other.elapsedMs == elapsedMs));
}


@override
int get hashCode => Object.hash(runtimeType,questionId,const DeepCollectionEquality().hash(givenAnswer),isCorrect,elapsedMs);

@override
String toString() {
  return 'AnswerRecord(questionId: $questionId, givenAnswer: $givenAnswer, isCorrect: $isCorrect, elapsedMs: $elapsedMs)';
}


}

/// @nodoc
abstract mixin class $AnswerRecordCopyWith<$Res>  {
  factory $AnswerRecordCopyWith(AnswerRecord value, $Res Function(AnswerRecord) _then) = _$AnswerRecordCopyWithImpl;
@useResult
$Res call({
 String questionId, List<String> givenAnswer, bool isCorrect, int elapsedMs
});




}
/// @nodoc
class _$AnswerRecordCopyWithImpl<$Res>
    implements $AnswerRecordCopyWith<$Res> {
  _$AnswerRecordCopyWithImpl(this._self, this._then);

  final AnswerRecord _self;
  final $Res Function(AnswerRecord) _then;

/// Create a copy of AnswerRecord
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? questionId = null,Object? givenAnswer = null,Object? isCorrect = null,Object? elapsedMs = null,}) {
  return _then(_self.copyWith(
questionId: null == questionId ? _self.questionId : questionId // ignore: cast_nullable_to_non_nullable
as String,givenAnswer: null == givenAnswer ? _self.givenAnswer : givenAnswer // ignore: cast_nullable_to_non_nullable
as List<String>,isCorrect: null == isCorrect ? _self.isCorrect : isCorrect // ignore: cast_nullable_to_non_nullable
as bool,elapsedMs: null == elapsedMs ? _self.elapsedMs : elapsedMs // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}



/// @nodoc


class _AnswerRecord implements AnswerRecord {
  const _AnswerRecord({required this.questionId, required final  List<String> givenAnswer, required this.isCorrect, required this.elapsedMs}): _givenAnswer = givenAnswer;
  

@override final  String questionId;
 final  List<String> _givenAnswer;
@override List<String> get givenAnswer {
  if (_givenAnswer is EqualUnmodifiableListView) return _givenAnswer;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_givenAnswer);
}

@override final  bool isCorrect;
@override final  int elapsedMs;

/// Create a copy of AnswerRecord
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AnswerRecordCopyWith<_AnswerRecord> get copyWith => __$AnswerRecordCopyWithImpl<_AnswerRecord>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AnswerRecord&&(identical(other.questionId, questionId) || other.questionId == questionId)&&const DeepCollectionEquality().equals(other._givenAnswer, _givenAnswer)&&(identical(other.isCorrect, isCorrect) || other.isCorrect == isCorrect)&&(identical(other.elapsedMs, elapsedMs) || other.elapsedMs == elapsedMs));
}


@override
int get hashCode => Object.hash(runtimeType,questionId,const DeepCollectionEquality().hash(_givenAnswer),isCorrect,elapsedMs);

@override
String toString() {
  return 'AnswerRecord(questionId: $questionId, givenAnswer: $givenAnswer, isCorrect: $isCorrect, elapsedMs: $elapsedMs)';
}


}

/// @nodoc
abstract mixin class _$AnswerRecordCopyWith<$Res> implements $AnswerRecordCopyWith<$Res> {
  factory _$AnswerRecordCopyWith(_AnswerRecord value, $Res Function(_AnswerRecord) _then) = __$AnswerRecordCopyWithImpl;
@override @useResult
$Res call({
 String questionId, List<String> givenAnswer, bool isCorrect, int elapsedMs
});




}
/// @nodoc
class __$AnswerRecordCopyWithImpl<$Res>
    implements _$AnswerRecordCopyWith<$Res> {
  __$AnswerRecordCopyWithImpl(this._self, this._then);

  final _AnswerRecord _self;
  final $Res Function(_AnswerRecord) _then;

/// Create a copy of AnswerRecord
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? questionId = null,Object? givenAnswer = null,Object? isCorrect = null,Object? elapsedMs = null,}) {
  return _then(_AnswerRecord(
questionId: null == questionId ? _self.questionId : questionId // ignore: cast_nullable_to_non_nullable
as String,givenAnswer: null == givenAnswer ? _self._givenAnswer : givenAnswer // ignore: cast_nullable_to_non_nullable
as List<String>,isCorrect: null == isCorrect ? _self.isCorrect : isCorrect // ignore: cast_nullable_to_non_nullable
as bool,elapsedMs: null == elapsedMs ? _self.elapsedMs : elapsedMs // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
