const $ = (id) => document.getElementById(id);

function localToday() {
  const now = new Date();
  return new Date(now.getTime() - now.getTimezoneOffset() * 60000).toISOString().slice(0, 10);
}

function esc(value) {
  return String(value).replace(/[&<>"']/g, (c) => ({
    "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;",
  }[c]));
}

async function api(path, options = {}) {
  const res = await fetch(path, { headers: { "Content-Type": "application/json" }, ...options });
  const body = await res.json().catch(() => ({}));
  if (!res.ok) {
    throw new Error(typeof body.detail === "string" ? body.detail : "Please check the details and try again.");
  }
  return body;
}

function showMessage(text, kind = "error") {
  const msg = $("msg");
  msg.textContent = text;
  msg.className = `msg ${kind}`;
  msg.hidden = !text;
}

async function loadStations() {
  const stations = await api("/api/trains/stations");
  for (const select of [$("from"), $("to")]) {
    select.innerHTML = stations.map((s) => `<option>${esc(s)}</option>`).join("");
  }
  $("to").selectedIndex = 1;
}

async function loadBookings() {
  const rows = await api("/api/bookings");
  $("bookings").innerHTML = rows.length
    ? rows.map((b) => `
        <tr>
          <td class="pnr">${esc(b.pnr)}</td>
          <td>${esc(b.name)}</td>
          <td>${esc(b.from_station)} to ${esc(b.to_station)}</td>
          <td>${esc(b.travel_date)}</td>
          <td>${esc(b.train_number)}</td>
          <td>Rs ${esc(b.fare)}</td>
        </tr>`).join("")
    : `<tr><td colspan="6" class="empty">No bookings yet.</td></tr>`;
}

let lastSearch = null;

async function searchTrains(event) {
  event.preventDefault();
  showMessage("");
  $("ticket").hidden = true;

  const search = {
    name: $("name").value.trim(),
    from: $("from").value,
    to: $("to").value,
    date: $("date").value,
  };
  if (search.from === search.to) {
    showMessage("From and To must be different stations.");
    return;
  }

  try {
    const query = new URLSearchParams({ from: search.from, to: search.to });
    const trains = await api(`/api/trains?${query}`);
    lastSearch = search;
    $("trains").innerHTML = trains.map((t) => `
      <div class="train">
        <div>
          <div class="tname">${esc(t.name)}</div>
          <div class="tmeta">#${esc(t.number)} | departs ${esc(t.departs)} | ${esc(search.date)}</div>
        </div>
        <div class="tright">
          <span class="fare">Rs ${esc(t.fare)}</span>
          <button type="button" data-number="${esc(t.number)}">Book</button>
        </div>
      </div>`).join("");
    $("trains-card").hidden = false;
  } catch (err) {
    showMessage(err.message);
  }
}

async function book(number) {
  showMessage("");
  try {
    const b = await api("/api/bookings", {
      method: "POST",
      body: JSON.stringify({
        name: lastSearch.name,
        from_station: lastSearch.from,
        to_station: lastSearch.to,
        travel_date: lastSearch.date,
        train_number: number,
      }),
    });
    $("ticket").innerHTML = `
      <div class="ticket-head">Ticket confirmed</div>
      <div class="ticket-grid">
        <div><span>PNR</span><b>${esc(b.pnr)}</b></div>
        <div><span>Passenger</span><b>${esc(b.name)}</b></div>
        <div><span>Route</span><b>${esc(b.from_station)} to ${esc(b.to_station)}</b></div>
        <div><span>Date</span><b>${esc(b.travel_date)}</b></div>
        <div><span>Train</span><b>${esc(b.train_name)} (#${esc(b.train_number)})</b></div>
        <div><span>Departs</span><b>${esc(b.departs)}</b></div>
        <div><span>Fare</span><b>Rs ${esc(b.fare)}</b></div>
      </div>`;
    $("ticket").hidden = false;
    $("trains-card").hidden = true;
    await loadBookings();
  } catch (err) {
    showMessage(err.message);
  }
}

$("trains").addEventListener("click", (event) => {
  const button = event.target.closest("button[data-number]");
  if (button) book(button.dataset.number);
});
$("search-form").addEventListener("submit", searchTrains);

$("date").min = localToday();
$("date").value = localToday();

loadStations().catch((err) => showMessage(err.message));
loadBookings().catch(() => showMessage("Could not load bookings from booking-service."));
