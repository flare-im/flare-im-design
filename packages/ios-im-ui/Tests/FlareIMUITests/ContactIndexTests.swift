import SwiftUI
import ViewInspector
import XCTest
@testable import FlareIMUI

/// K7 (FR-044): the contact list indexes Chinese names by pinyin initial, Latin names by letter and
/// everything else under "#" last, with names ordered by their reading.
final class ContactIndexTests: XCTestCase {
    func testChineseNamesIndexByPinyinInitialAndLatinByLetter() {
        XCTAssertEqual(ContactListView.indexLetter(name: "张伟"), "Z")
        XCTAssertEqual(ContactListView.indexLetter(name: "李娜"), "L")
        XCTAssertEqual(ContactListView.indexLetter(name: "陈静"), "C")
        XCTAssertEqual(ContactListView.indexLetter(name: "欧阳娜娜"), "O")
        XCTAssertEqual(ContactListView.indexLetter(name: "  王芳"), "W", "leading spaces are ignored")
        XCTAssertEqual(ContactListView.indexLetter(name: "ada"), "A")
        XCTAssertEqual(ContactListView.indexLetter(name: "Émile"), "E", "accents fold away")
        XCTAssertEqual(ContactListView.indexLetter(name: "Ｂｏｂ"), "B", "full-width letters fold")
    }

    func testEverythingElseGoesUnderTheOtherIndex() {
        XCTAssertEqual(ContactListView.indexLetter(name: "7-Eleven"), "#")
        XCTAssertEqual(ContactListView.indexLetter(name: "😀 Ann"), "#")
        XCTAssertEqual(ContactListView.indexLetter(name: "Анна"), "#", "another script is not transliterated")
        XCTAssertEqual(ContactListView.indexLetter(name: "さくら"), "#", "kana is not pinyin")
        XCTAssertEqual(ContactListView.indexLetter(name: ""), "#")
    }

    func testAHostIndexKeyIsUsedAsGiven() {
        XCTAssertEqual(ContactListView.indexLetter(name: "曾小贤", indexKey: "zeng"), "Z", "the host knows the surname reading")
        XCTAssertEqual(ContactListView.indexLetter(name: "Ada", indexKey: "#"), "#")
        XCTAssertEqual(ContactListView.indexLetter(name: "Ada", indexKey: "张"), "#", "a key is not transliterated")
    }

    func testGroupsRunAToZThenOtherAndNamesFollowTheirReading() {
        let contacts = ["赵六", "#tag", "Zoe", "张三", "阿强", "Bob", "李四", "Amy", "123"].enumerated().map {
            Contact(id: "c\($0.offset)", name: $0.element)
        }
        let groups = ContactListView.indexGroups(contacts)
        XCTAssertEqual(groups.map(\.letter), ["A", "B", "L", "Z", "#"])
        XCTAssertEqual(groups.first { $0.letter == "A" }?.people.map(\.name), ["阿强", "Amy"], "a qiang before amy")
        XCTAssertEqual(groups.first { $0.letter == "Z" }?.people.map(\.name), ["张三", "赵六", "Zoe"])
        XCTAssertEqual(groups.last?.people.count, 2)
    }

    @MainActor
    func testTheListDrawsTheOtherSectionLast() throws {
        let list = ContactListView(items: [Contact(id: "1", name: "123"), Contact(id: "2", name: "王芳"), Contact(id: "3", name: "Ada")])
        let texts = try list.inspect().findAll(ViewType.Text.self).compactMap { try? $0.string() }
        XCTAssertEqual(Array(texts.suffix(3)), ["A", "W", "#"], "the side index runs A to Z, then #: \(texts)")
        let ada = try XCTUnwrap(texts.firstIndex(of: "Ada")), wang = try XCTUnwrap(texts.firstIndex(of: "王芳"))
        let other = try XCTUnwrap(texts.firstIndex(of: "123"))
        XCTAssertLessThan(ada, wang)
        XCTAssertLessThan(wang, other, "names under # come last: \(texts)")
    }
}
