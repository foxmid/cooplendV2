import 'dart:developer';

import 'package:ascoop/web_ui/constants.dart';
import 'package:ascoop/web_ui/route/subs/header.dart';
import 'package:ascoop/web_ui/styles/inputstyle.dart';
import 'package:ascoop/web_ui/styles/textstyles.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ListLoanCom extends StatefulWidget {
  Function callback;
  ListLoanCom({super.key, required this.callback});

  @override
  State<ListLoanCom> createState() => _ListLoanComState();
}

class _ListLoanComState extends State<ListLoanCom> {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 480,
      height: MediaQuery.of(context).size.height,
      decoration: const BoxDecoration(
        border: Border(
            right: BorderSide(
                width: 1.0, color: Color.fromARGB(255, 203, 203, 203))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HeaderText(
            Ttl: 'All Completed Loans',
            subTtl: 'Completed Loans',
          ),
          Expanded(
            child: LoanList(
              callback: widget.callback,
            ),
          ),
        ],
      ),
    );
  }
}

class LoanList extends StatefulWidget {
  Function callback;
  LoanList({
    super.key,
    required this.callback,
  });

  @override
  State<LoanList> createState() => _LoanListState();
}

class _LoanListState extends State<LoanList> {
  late final TextEditingController _search;
  bool _obscure = true;
  FocusNode myFocusNode = FocusNode();
  String searchStr = "";
  bool isSearch = true;
  @override
  void initState() {
    _search = TextEditingController();
    super.initState();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: MediaQuery.of(context).size.width,
      height: MediaQuery.of(context).size.height,
      child: Column(
        children: [
          Container(
            width: MediaQuery.of(context).size.width,
            padding: const EdgeInsets.fromLTRB(15, 5, 15, 10),
            child: TextFormField(
              style: inputTextStyle,
              keyboardType: TextInputType.emailAddress,
              controller: _search,
              decoration: InputDecoration(
                hintStyle: inputHintTxtStyle,
                focusedBorder: focusSearchBorder,
                border: SearchBorder,
                hintText: "Search Loan Number or Subscriber's Name",
                prefixIcon: Icon(
                  Feather.search,
                  size: 20,
                  color: Colors.red[800],
                ),
              ),
              onChanged: (str) {
                setState(() {
                  searchStr = str;
                });
                if (str.isEmpty) {
                  setState(() {
                    isSearch = true;
                  });
                } else {
                  setState(() {
                    isSearch = false;
                  });
                }
              },
            ),
          ),
          Expanded(
            child: LoanComList(
              searchStr: searchStr,
              callback: widget.callback,
              isSearch: isSearch,
            ),
          ),
        ],
      ),
    );
  }
}

class LoanComList extends StatefulWidget {
  String searchStr;
  Function callback;
  bool isSearch;
  LoanComList(
      {this.searchStr = '',
      required this.callback,
      required this.isSearch,
      super.key});

  @override
  State<LoanComList> createState() => _LoanComListState();
}

class _LoanComListState extends State<LoanComList> {
  late final SharedPreferences prefs;
  late final prefsFuture =
      SharedPreferences.getInstance().then((v) => prefs = v);
  var _controller = ScrollController(keepScrollOffset: true);
  var _loan = <bool>[];
  int cnt = 0;
  list(int count) {
    cnt = count;
    for (int a = 0; a < cnt; a++) {
      _loan.add(false);
    }
  }

  select(int num) {
    for (int i = 0; i < cnt; i++) {
      if (i != num) {
        _loan[i] = false;
      } else {
        _loan[i] = true;
      }
    }
  }

  @override
  void dispose() {
    _loan;
    widget.searchStr;
    cnt;
    _controller;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width,
      height: MediaQuery.of(context).size.height,
      child: FutureBuilder(
        future: prefsFuture,
        builder: (context, prefs) {
          if (prefs.hasError) {
            return const Center(child: CircularProgressIndicator());
          } else {
            switch (prefs.connectionState) {
              case ConnectionState.waiting:
                return onWait;
              default:
                return StreamBuilder(
                  stream: myDb
                      .collection('loans')
                      .where('coopId',
                          isEqualTo: prefs.data!.getString('coopId'))
                      .where('loanStatus', isEqualTo: 'completed')
                      .orderBy('completeAt', descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    try {
                      final data = snapshot.data!.docs;
                      if (snapshot.hasError) {
                        log('snapshot.hasError (listloan): ${snapshot.error}');
                        return Container();
                      } else if (snapshot.hasData && data.isNotEmpty) {
                        switch (snapshot.connectionState) {
                          case ConnectionState.waiting:
                            return onWait;
                          default:
                            list(data.length); //get all subs to array of bool
                            return Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Visibility(
                                  visible: widget.isSearch,
                                  child: Container(
                                    padding:
                                        const EdgeInsets.fromLTRB(15, 5, 10, 0),
                                    child: Text(
                                      '${NumberFormat('###,###,###').format(data.length.toInt())} Completed Loans',
                                      style: TextStyle(
                                        fontFamily: FontNameDefault,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.red[900],
                                      ),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: SizedBox(
                                    width: MediaQuery.of(context).size.width,
                                    child: ListView.builder(
                                      shrinkWrap: true,
                                      scrollDirection: Axis.vertical,
                                      controller: _controller,
                                      itemCount: data.length,
                                      itemBuilder: (context, index) {
                                        var listOf = InkWell(
                                          hoverColor: Colors.transparent,
                                          splashColor: Colors.transparent,
                                          onTap: () {
                                            setState(() {
                                              int sel = index;
                                              setState(() {
                                                select(sel);
                                                widget.callback(
                                                    data[sel]['loanId']);
                                              });
                                            });
                                          },
                                          child: Container(
                                            margin: const EdgeInsets.fromLTRB(
                                                15, 8, 15, 8),
                                            padding: const EdgeInsets.fromLTRB(
                                                8, 8, 0, 8),
                                            width: MediaQuery.of(context)
                                                .size
                                                .width,
                                            decoration: BoxDecoration(
                                                color: Colors.white,
                                                borderRadius:
                                                    BorderRadius.circular(15),
                                                border: Border.all(
                                                    color: _loan[index] == true
                                                        ? red8
                                                        : Colors.transparent,
                                                    width: 2),
                                                boxShadow: [
                                                  BoxShadow(
                                                      color:
                                                          _loan[index] == true
                                                              ? red8
                                                              : grey4,
                                                      spreadRadius: 0.2,
                                                      blurStyle:
                                                          BlurStyle.normal,
                                                      blurRadius: 1.6),
                                                ]),
                                            child: Row(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Container(
                                                  width: 90,
                                                  padding:
                                                      const EdgeInsets.all(8.0),
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .center,
                                                    children: [
                                                      CircularPercentIndicator(
                                                        radius: 40,
                                                        lineWidth: 4.0,
                                                        percent: data[index][
                                                                'noMonthsPaid'] /
                                                            data[index]
                                                                ['noMonths'],
                                                        center: Center(
                                                          child: Text(
                                                            // ignore: prefer_interpolation_to_compose_strings
                                                            NumberFormat("##0",
                                                                        "en_US")
                                                                    .format((data[index]
                                                                            [
                                                                            'noMonthsPaid'] /
                                                                        data[index]
                                                                            [
                                                                            'noMonths'] *
                                                                        100))
                                                                    .toString() +
                                                                '%',
                                                            style: const TextStyle(
                                                                fontFamily:
                                                                    FontNameDefault,
                                                                fontSize: 16,
                                                                color: Colors
                                                                    .black,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w800),
                                                          ),
                                                        ),
                                                        progressColor:
                                                            Colors.red[800],
                                                      ),
                                                      const Padding(
                                                          padding: EdgeInsets
                                                              .symmetric(
                                                                  vertical: 2)),
                                                      Text(
                                                        '${data[index]['loanType']} loan'
                                                            .toUpperCase(),
                                                        style: const TextStyle(
                                                          fontFamily:
                                                              FontNameDefault,
                                                          fontSize: 10,
                                                          fontWeight:
                                                              FontWeight.w400,
                                                          color: Colors.black,
                                                        ),
                                                        textAlign:
                                                            TextAlign.center,
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                const Padding(
                                                    padding:
                                                        EdgeInsets.symmetric(
                                                            horizontal: 4)),
                                                Expanded(
                                                  child: SizedBox(
                                                    width:
                                                        MediaQuery.of(context)
                                                            .size
                                                            .width,
                                                    child: Row(
                                                      children: [
                                                        SizedBox(
                                                          width: 135,
                                                          child: Column(
                                                            crossAxisAlignment:
                                                                CrossAxisAlignment
                                                                    .start,
                                                            children: [
                                                              Column(
                                                                crossAxisAlignment:
                                                                    CrossAxisAlignment
                                                                        .start,
                                                                children: [
                                                                  const Text(
                                                                    'LOAN AMOUNT',
                                                                    style:
                                                                        TextStyle(
                                                                      fontFamily:
                                                                          FontNameDefault,
                                                                      fontSize:
                                                                          12,
                                                                      letterSpacing:
                                                                          1,
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .w400,
                                                                      color: Colors
                                                                          .black,
                                                                    ),
                                                                  ),
                                                                  Text(
                                                                    'PHP ${NumberFormat('###,###,###,###.##').format(data[index]['loanAmount'])}',
                                                                    style:
                                                                        const TextStyle(
                                                                      fontFamily:
                                                                          FontNameDefault,
                                                                      fontSize:
                                                                          16,
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .w700,
                                                                      color: Colors
                                                                          .black,
                                                                    ),
                                                                  ),
                                                                ],
                                                              ),
                                                              const Padding(
                                                                  padding: EdgeInsets
                                                                      .symmetric(
                                                                          vertical:
                                                                              3)),
                                                              Column(
                                                                crossAxisAlignment:
                                                                    CrossAxisAlignment
                                                                        .start,
                                                                children: [
                                                                  const Text(
                                                                    'DATE COMPLETED',
                                                                    style:
                                                                        TextStyle(
                                                                      fontFamily:
                                                                          FontNameDefault,
                                                                      fontSize:
                                                                          12,
                                                                      letterSpacing:
                                                                          1,
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .w400,
                                                                      color: Colors
                                                                          .black,
                                                                    ),
                                                                  ),
                                                                  Text(
                                                                    DateFormat(
                                                                            'MMM d, yyyy')
                                                                        .format(
                                                                            data[index]['completeAt'].toDate())
                                                                        .toUpperCase(),
                                                                    style:
                                                                        const TextStyle(
                                                                      fontFamily:
                                                                          FontNameDefault,
                                                                      fontSize:
                                                                          16,
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .w700,
                                                                      color: Colors
                                                                          .black,
                                                                    ),
                                                                  ),
                                                                ],
                                                              ),
                                                              const Padding(
                                                                  padding: EdgeInsets
                                                                      .symmetric(
                                                                          vertical:
                                                                              3)),
                                                              Column(
                                                                crossAxisAlignment:
                                                                    CrossAxisAlignment
                                                                        .start,
                                                                children: [
                                                                  const Text(
                                                                    'TOTAL PAID',
                                                                    style:
                                                                        TextStyle(
                                                                      fontFamily:
                                                                          FontNameDefault,
                                                                      fontSize:
                                                                          12,
                                                                      letterSpacing:
                                                                          1,
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .w400,
                                                                      color: Colors
                                                                          .black,
                                                                    ),
                                                                  ),
                                                                  Text(
                                                                    'PHP ${NumberFormat('###,###,###,###.##').format(data[index]['paidAmount'])}',
                                                                    style:
                                                                        const TextStyle(
                                                                      fontFamily:
                                                                          FontNameDefault,
                                                                      fontSize:
                                                                          16,
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .w700,
                                                                      color: Colors
                                                                          .black,
                                                                    ),
                                                                  ),
                                                                ],
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                                SizedBox(
                                                  width: 195,
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          Column(
                                                            crossAxisAlignment:
                                                                CrossAxisAlignment
                                                                    .start,
                                                            children: [
                                                              const Text(
                                                                'LOAN NUMBER',
                                                                style:
                                                                    TextStyle(
                                                                  fontFamily:
                                                                      FontNameDefault,
                                                                  fontSize: 12,
                                                                  letterSpacing:
                                                                      1,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w400,
                                                                  color: Colors
                                                                      .black,
                                                                ),
                                                              ),
                                                              Text(
                                                                '${data[index]['loanId']}',
                                                                style:
                                                                    const TextStyle(
                                                                  fontFamily:
                                                                      FontNameDefault,
                                                                  fontSize: 16,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w700,
                                                                  color: Colors
                                                                      .black,
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                          const Padding(
                                                              padding: EdgeInsets
                                                                  .symmetric(
                                                                      vertical:
                                                                          3)),
                                                          const Text(
                                                            "SUBSCRIBER'S NAME",
                                                            style: TextStyle(
                                                              fontFamily:
                                                                  FontNameDefault,
                                                              fontSize: 12,
                                                              letterSpacing: 1,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w400,
                                                              color:
                                                                  Colors.black,
                                                            ),
                                                          ),
                                                          StreamBuilder(
                                                            stream: FirebaseFirestore
                                                                .instance
                                                                .collection(
                                                                    'subscribers')
                                                                .where('userId',
                                                                    isEqualTo: data[
                                                                            index]
                                                                        [
                                                                        'userId'])
                                                                .snapshots(),
                                                            builder: (context,
                                                                snapshot) {
                                                              try {
                                                                if (snapshot
                                                                    .hasError) {
                                                                  log('snapshot.hasError (coopdash): ${snapshot.error}');
                                                                  return Container();
                                                                } else if (snapshot
                                                                    .hasData) {
                                                                  switch (snapshot
                                                                      .connectionState) {
                                                                    case ConnectionState
                                                                        .waiting:
                                                                      return onWait;
                                                                    default:
                                                                      return Text(
                                                                        '${snapshot.data!.docs[0]['userFirstName']} ${snapshot.data!.docs[0]['userMiddleName'].toString()[0]}. ${snapshot.data!.docs[0]['userLastName']}'
                                                                            .toUpperCase(),
                                                                        style:
                                                                            const TextStyle(
                                                                          fontFamily:
                                                                              FontNameDefault,
                                                                          fontSize:
                                                                              16,
                                                                          fontWeight:
                                                                              FontWeight.w700,
                                                                          color:
                                                                              Colors.black,
                                                                        ),
                                                                        overflow:
                                                                            TextOverflow.ellipsis,
                                                                      );
                                                                  }
                                                                }
                                                              } catch (e) {
                                                                log(e
                                                                    .toString());
                                                              }
                                                              return Container();
                                                            },
                                                          ),
                                                          const Padding(
                                                              padding: EdgeInsets
                                                                  .symmetric(
                                                                      vertical:
                                                                          3)),
                                                          Column(
                                                            crossAxisAlignment:
                                                                CrossAxisAlignment
                                                                    .start,
                                                            children: [
                                                              const Text(
                                                                'LOAN TENURE',
                                                                style:
                                                                    TextStyle(
                                                                  fontFamily:
                                                                      FontNameDefault,
                                                                  fontSize: 12,
                                                                  letterSpacing:
                                                                      1,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w400,
                                                                  color: Colors
                                                                      .black,
                                                                ),
                                                              ),
                                                              Text(
                                                                '${NumberFormat("###,##0", "en_US").format(data[index]['noMonths'])} MONTHS',
                                                                style:
                                                                    const TextStyle(
                                                                  fontFamily:
                                                                      FontNameDefault,
                                                                  fontSize: 16,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w700,
                                                                  color: Colors
                                                                      .black,
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ],
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        );

                                        if (widget.searchStr.trim().isEmpty) {
                                          return listOf;
                                        }
                                        // if ('${data[index]['userFirstName']} ${data[index]['userMiddleName']} ${data[index]['userLastName']}'
                                        //     .trim()
                                        //     .toLowerCase()
                                        //     .startsWith(widget.searchStr
                                        //         .trim()
                                        //         .toString()
                                        //         .toLowerCase())) {
                                        //   return listOf;
                                        // }
                                        // if ('${data[index]['userFirstName']} ${data[index]['userLastName']} ${data[index]['userMiddleName']}'
                                        //     .trim()
                                        //     .toLowerCase()
                                        //     .startsWith(widget.searchStr
                                        //         .trim()
                                        //         .toString()
                                        //         .toLowerCase())) {
                                        //   return listOf;
                                        // }
                                        // if ('${data[index]['userMiddleName']} ${data[index]['userFirstName']} ${data[index]['userLastName']}'
                                        //     .trim()
                                        //     .toLowerCase()
                                        //     .startsWith(widget.searchStr
                                        //         .trim()
                                        //         .toString()
                                        //         .toLowerCase())) {
                                        //   return listOf;
                                        // }
                                        // if ('${data[index]['userMiddleName']} ${data[index]['userLastName']} ${data[index]['userFirstName']}'
                                        //     .trim()
                                        //     .toLowerCase()
                                        //     .startsWith(widget.searchStr
                                        //         .trim()
                                        //         .toString()
                                        //         .toLowerCase())) {
                                        //   return listOf;
                                        // }
                                        // if ('${data[index]['userLastName']} ${data[index]['userMiddleName']} ${data[index]['userFirstName']}'
                                        //     .trim()
                                        //     .toLowerCase()
                                        //     .startsWith(widget.searchStr
                                        //         .trim()
                                        //         .toString()
                                        //         .toLowerCase())) {
                                        //   return listOf;
                                        // }
                                        // if ('${data[index]['userLastName']} ${data[index]['userFirstName']} ${data[index]['userMiddleName']}'
                                        //     .trim()
                                        //     .toLowerCase()
                                        //     .startsWith(widget.searchStr
                                        //         .trim()
                                        //         .toString()
                                        //         .toLowerCase())) {
                                        //   return listOf;
                                        // }

                                        // //reciprocal
                                        // if ('${data[index]['userFirstName']} ${data[index]['userMiddleName']} ${data[index]['userLastName']}'
                                        //     .trim()
                                        //     .toUpperCase()
                                        //     .startsWith(widget.searchStr
                                        //         .trim()
                                        //         .toString()
                                        //         .toUpperCase())) {
                                        //   return listOf;
                                        // }
                                        // if ('${data[index]['userFirstName']} ${data[index]['userLastName']} ${data[index]['userMiddleName']}'
                                        //     .trim()
                                        //     .toUpperCase()
                                        //     .startsWith(widget.searchStr
                                        //         .trim()
                                        //         .toString()
                                        //         .toUpperCase())) {
                                        //   return listOf;
                                        // }
                                        // if ('${data[index]['userMiddleName']} ${data[index]['userFirstName']} ${data[index]['userLastName']}'
                                        //     .trim()
                                        //     .toUpperCase()
                                        //     .startsWith(widget.searchStr
                                        //         .trim()
                                        //         .toString()
                                        //         .toUpperCase())) {
                                        //   return listOf;
                                        // }
                                        // if ('${data[index]['userMiddleName']} ${data[index]['userLastName']} ${data[index]['userFirstName']}'
                                        //     .trim()
                                        //     .toUpperCase()
                                        //     .startsWith(widget.searchStr
                                        //         .trim()
                                        //         .toString()
                                        //         .toUpperCase())) {
                                        //   return listOf;
                                        // }
                                        // if ('${data[index]['userLastName']} ${data[index]['userMiddleName']} ${data[index]['userFirstName']}'
                                        //     .trim()
                                        //     .toUpperCase()
                                        //     .startsWith(widget.searchStr
                                        //         .trim()
                                        //         .toString()
                                        //         .toUpperCase())) {
                                        //   return listOf;
                                        // }
                                        // if ('${data[index]['userLastName']} ${data[index]['userFirstName']} ${data[index]['userMiddleName']}'
                                        //     .trim()
                                        //     .toUpperCase()
                                        //     .startsWith(widget.searchStr
                                        //         .trim()
                                        //         .toString()
                                        //         .toUpperCase())) {
                                        //   return listOf;
                                        // }

                                        if (data[index]['loanId']
                                            .toString()
                                            .trim()
                                            .toLowerCase()
                                            .startsWith(widget.searchStr
                                                .trim()
                                                .toString()
                                                .toLowerCase())) {
                                          return listOf;
                                        }
                                        if (data[index]['loanId']
                                            .toString()
                                            .trim()
                                            .toUpperCase()
                                            .startsWith(widget.searchStr
                                                .trim()
                                                .toString()
                                                .toUpperCase())) {
                                          return listOf;
                                        }

                                        return Container();
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            );
                        }
                      } else if (data.isEmpty) {
                        return EmptyData(ttl: 'No Complete Loans Yet');
                      }
                    } catch (e) {
                      log('listloan.dart error (stream): ${e.toString()}');
                    }
                    return Container(/** if null */);
                  },
                );
            }
          }
        },
      ),
    );
  }
}
