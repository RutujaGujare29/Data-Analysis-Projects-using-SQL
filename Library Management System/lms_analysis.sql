--Read all tables
SELECT * FROM books;
SELECT * FROM branch;
SELECT * FROM employees;
SELECT * FROM issued_status;
SELECT * FROM return_status;
SELECT * FROM members;

--1. Create a New Book Record -- "978-1-60129-456-2', 'To Kill a Mockingbird', 'Classic', 6.00, 'yes', 'Harper Lee', 'J.B. Lippincott & Co.')"

INSERT INTO books (isbn, book_title, category, rental_price, status, author, publisher)
VALUES ('978-1-60129-456-2', 'To Kill a Mockingbird', 'Classic', 6.00, 'yes', 'Harper Lee', 'J.B. Lippincott & Co.');
SELECT * FROM books;

--2. Update an Existing Member's Address
UPDATE members 
SET member_address='125 Main St'
where member_id='C101';
SELECT * FROM members;

--3. Delete a Record from the Issued Status Table 
DELETE FROM issued_status 
WHERE issued_id ='ISI121';

--4. Retrieve All Books Issued by a Specific Employee with emp_id = 'E101'
SELECT * FROM issued_status
WHERE issued_emp_id='E101';

--5. List Names of employees Who Have Issued More Than One Book 
SELECT
	i.issued_emp_id,
	e.emp_name
FROM employees e
JOIN issued_status i 
ON i.issued_emp_id =  e.emp_id
GROUP BY i.issued_emp_id, e.emp_name
HAVING COUNT(i.issued_emp_id)>1
ORDER BY i.issued_emp_id;

--6. Using CTAS to generate new summmary tables based on query results - each book and total book_issued_cnt**
CREATE TABLE book_count
AS
SELECT
	b.isbn,
	b.book_title,
	COUNT(i.issued_id) AS book_issued_cnt
FROM books b
JOIN issued_status i
ON b.isbn = i.issued_book_isbn
GROUP BY 1, 2;

SELECT * FROM book_count;

--7. Retrieve All Books in a Specific Category: 'Classic'
SELECT * FROM books
WHERE category='Classic';

--8. Find Total Rental Income by Category
SELECT 
	b.category,
	SUM(b.rental_price) AS rental_amount
FROM books b
JOIN issued_status i
ON b.isbn = i.issued_book_isbn
GROUP BY b.category
ORDER BY rental_amount DESC;

--9. List Members Who Registered in the Last 180 Days
SELECT * FROM members
WHERE reg_date >= CURRENT_DATE - INTERVAL '180 days';

--10. List Employees with Their Branch Manager's Name and their branch details
SELECT
	e1.*,
	b.manager_id,
	e2.emp_name AS manager_name,
	b.branch_address
FROM employees e1 
JOIN branch b ON e1.branch_id = b.branch_id
JOIN employees e2 ON b.manager_id = e2.emp_id;

--11. Create a Table of Books with Rental Price Above a Certain Threshold 7USD
CREATE TABLE higher_range_books
AS
SELECT	* FROM books
WHERE rental_price > 7;

SELECT * FROM higher_range_books ORDER BY rental_price DESC;

--12. Retrieve the List of Books Not Yet Returned
SELECT 
	issued_id,
	issued_book_name
FROM issued_status ist
WHERE NOT EXISTS (
	SELECT issued_id
	FROM return_status rs
	WHERE ist.issued_id = rs.issued_id
);
	
--13. Query to identify members who have overdue books (assume a 30-day return period).
-- Display the member's_id, member's name, book title, issue date, and days overdue.
WITH overdue_books AS (
SELECT
	ist.issued_member_id,
	m.member_name,
	ist.issued_book_name,
	ist.issued_date,
	CURRENT_DATE - ist.issued_date as overdue_days
FROM issued_status ist
JOIN members m ON ist.issued_member_id = m.member_id
WHERE NOT EXISTS (
	SELECT issued_id
	FROM return_status rs
	WHERE ist.issued_id = rs.issued_id
))

SELECT * FROM overdue_books
WHERE overdue_days > 30;

--14. Update Book Status on Return
--Query to update the status of books in the books table to "Yes" when they are returned (based on entries in the return_status table).
-- As soon as an entry is noted in the return_status table for a book, automatically the status in books table should be set to 'yes'
-- Can be done manually too but to avoid rerunning the code multiple times stored procedures could be used

--Stored procedures
CREATE OR REPLACE PROCEDURE add_return_records(p_return_id VARCHAR(10), p_issued_id VARCHAR(10))
LANGUAGE plpgsql
AS $$

DECLARE
	v_isbn VARCHAR(50);
	v_book_name VARCHAR(80);
	
BEGIN
	INSERT INTO return_status(return_id, issued_id, return_date)
	VALUES(p_return_id, p_issued_id, CURRENT_DATE);

	SELECT
		issued_book_isbn,
		issued_book_name
		INTO
		v_isbn, 
		v_book_name
	FROM issued_status
	WHERE issued_id = p_issued_id;

	UPDATE books 
	SET status='yes'
	WHERE isbn=v_isbn;

	RAISE NOTICE 'Thank you for returning the book: %', v_book_name;

END;
$$

--Testing function add_return_records
SELECT * FROM books
WHERE isbn = '978-0-307-58837-1';

SELECT * FROM issued_status
WHERE issued_book_isbn = '978-0-307-58837-1';

SELECT * FROM return_status
WHERE return_book_isbn = '978-0-307-58837-1';
--issued_id = 'IS135'

--calling function add_return_records
CALL add_return_records('RS119', 'IS135');

--15. Branch Performance Report
--Query that generates a performance report for each branch and manager
--Showing the number of books issued, the number of books returned, and the total revenue generated from book rentals.
CREATE TABLE branch_reports 
AS 
SELECT
	b.branch_id,
	b.manager_id,
	COUNT(ist.issued_id) AS no_books_issued,
	COUNT(rs.return_id) AS no_books_returned,
	SUM(bk.rental_price) AS total_revenue
FROM issued_status ist
JOIN employees e ON ist.issued_emp_id = e.emp_id
JOIN branch b ON e.branch_id = b.branch_id
JOIN books bk ON ist.issued_book_isbn = bk.isbn
LEFT JOIN return_status rs ON ist.issued_id = rs.issued_id
GROUP BY 1,2;

SELECT * FROM branch_reports;

--16. Create a Table of Active Members
--Table of active_members containing members who have issued at least one book in the last 2 months
CREATE TABLE active_members
AS
SELECT * FROM members
WHERE member_id IN(
SELECT
	DISTINCT issued_member_id
FROM issued_status
WHERE issued_date >=CURRENT_DATE - INTERVAL '2 month');

SELECT * FROM active_members;

--17. Find Employees with the Most Book Issues Processed
-- Query to find the top 3 employees who have processed the most book issues. 
-- Display the employee name, number of books processed, and their branch.
SELECT 
	e.emp_name,
	b.*,
	COUNT(ist.issued_id) AS books_issued
FROM issued_status ist
JOIN employees e ON e.emp_id = ist.issued_emp_id
JOIN branch b ON e.branch_id = b.branch_id
GROUP BY 1,2
LIMIT 3;

--18. A stored procedure that updates the status of a book in the library based on its issuance. 
--The procedure should function as follows: 
--The procedure should first check if the book is available (status = 'yes'). 
--If the book is available, it should be issued, and the status in the books table should be updated to 'no'. 
--If the book is not available (status = 'no'), the procedure should return an error message indicating that the book is currently not available.
CREATE OR REPLACE PROCEDURE issue_book(p_issued_id VARCHAR(10), p_issued_member_id VARCHAR(30), p_issued_book_isbn VARCHAR(30), p_issued_emp_id VARCHAR(10))
LANGUAGE plpgsql
AS $$

DECLARE
--variable
v_status VARCHAR(10);

BEGIN
	--main body of the code
	--checking if the book is available, status = 'yes'
	SELECT
		status
		INTO
		v_status
	FROM books
	WHERE isbn = p_issued_book_isbn;

	IF v_status = 'yes' THEN
		INSERT INTO issued_status(issued_id, issued_member_id, issued_date, issued_book_isbn, issued_emp_id)
		VALUES(p_issued_id, p_issued_member_id, CURRENT_DATE, p_issued_book_isbn, p_issued_emp_id);

		UPDATE books
		SET status='no'
		WHERE isbn = p_issued_book_isbn;
	
		RAISE NOTICE 'Book records added successfully for book isbn : %', p_issued_book_isbn;

	ELSE
		RAISE NOTICE 'Sorry to inform you the book you have requested is unavailable - book_isbn: %', p_issued_book_isbn;
	END IF;
	
END;
$$

--testing function
CALL issue_book('IS155', 'C108', '978-0-553-29698-2', 'E104');

CALL issue_book('IS156', 'C108', '978-0-375-41398-8', 'E104');