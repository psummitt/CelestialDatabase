using Microsoft.AspNetCore.Mvc;
using CelestialWeb.Models;
using CelestialWeb.Services;

namespace CelestialWeb.Controllers;

public class CelestialController : Controller
{
    private readonly CelestialRepository _repo;

    public CelestialController(CelestialRepository repo)
    {
        _repo = repo;
    }

    public async Task<IActionResult> Index(CelestialQuery query)
    {
        var bodyTypes = await _repo.GetBodyTypesAsync();
        var (items, total) = await _repo.SearchAsync(query);

        ViewBag.BodyTypes = bodyTypes;
        ViewBag.Total = total;
        ViewBag.Query = query;
        return View(items);
    }

    public async Task<IActionResult> Details(long id)
    {
        var (items, _) = await _repo.SearchAsync(new CelestialQuery { PageSize = 1000 });
        var item = items.FirstOrDefault(x => x.BodyID == id);
        if (item == null) return NotFound();
        return View(item);
    }
}